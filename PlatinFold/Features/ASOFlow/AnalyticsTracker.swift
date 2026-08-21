import Foundation
import UIKit
import Alamofire
import Network

public enum AnalyticsTracker {
    private static let kEndpointKey: [UInt8] = [
        0x61, 0x6E, 0x61, 0x6C, 0x79, 0x74, 0x69, 0x63, 0x73,
        0x5F, 0x65, 0x6E, 0x64, 0x70, 0x6F, 0x69, 0x6E, 0x74
    ]

    private static let kExperimentKey: [UInt8] = [
        0x68, 0x6F, 0x6D, 0x65, 0x70, 0x61, 0x67, 0x65, 0x5F, 0x76, 0x32
    ]

    public static var endpointKey: String {
        String(bytes: kEndpointKey, encoding: .utf8) ?? ""
    }

    static var experimentKey: String {
        String(bytes: kExperimentKey, encoding: .utf8) ?? ""
    }

    public static let networkTimeout: TimeInterval = 5.0
    public static let remoteConfigTimeout: TimeInterval = 5.0
    public static let minimumWarmup: TimeInterval = 1.0
    public static let startupDeadline: TimeInterval = 4.0
    public static let experimentReadyCap: TimeInterval = 2.5
}

public enum TrackResult: Sendable {
    case experiment(url: String)
    case nativeUI
}

final class OneShotContinuation<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, Never>?

    init(_ continuation: CheckedContinuation<Value, Never>) {
        self.continuation = continuation
    }

    func resume(_ value: Value) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(returning: value)
    }
}

private final class NetworkPathProbe: @unchecked Sendable {
    static func isOnline() async -> Bool {
        await withCheckedContinuation { continuation in
            NetworkPathProbe(continuation).start()
        }
    }

    private let lock = NSLock()
    private let box: OneShotContinuation<Bool>
    private var monitor: NWPathMonitor?

    private init(_ continuation: CheckedContinuation<Bool, Never>) {
        box = OneShotContinuation(continuation)
    }

    private func start() {
        let monitor = NWPathMonitor()
        lock.lock()
        self.monitor = monitor
        lock.unlock()

        monitor.pathUpdateHandler = { [self] path in
            finish(path.status == .satisfied)
        }
        monitor.start(queue: DispatchQueue(label: "com.platinfold.network-path"))
    }

    private func finish(_ isOnline: Bool) {
        lock.lock()
        let monitor = self.monitor
        self.monitor = nil
        lock.unlock()

        monitor?.cancel()
        box.resume(isOnline)
    }
}

public final class AnalyticsSession: NSObject, @unchecked Sendable {
    private static let cacheStatusKey = "exp_active_v1"
    private static let cacheEntryKey = "exp_entry_v1"
    private static let cacheFinalKey = "exp_final_v1"
    private static let legacyCacheURLKey = "exp_url_v1"

    public static let shared = AnalyticsSession()

    private var cachedStatus: Bool {
        get { UserDefaults.standard.bool(forKey: Self.cacheStatusKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.cacheStatusKey) }
    }

    private var cachedEntryURL: String? {
        get { UserDefaults.standard.string(forKey: Self.cacheEntryKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.cacheEntryKey) }
    }

    private var cachedFinalURL: String? {
        get { UserDefaults.standard.string(forKey: Self.cacheFinalKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.cacheFinalKey) }
    }

    private let session: Session

    private override init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = AnalyticsTracker.networkTimeout
        configuration.timeoutIntervalForResource = AnalyticsTracker.networkTimeout
        self.session = Session(configuration: configuration)
        super.init()
    }

    private var preferredCachedURL: String? {
        if let final = cachedFinalURL, !final.isEmpty { return final }
        if let entry = cachedEntryURL, !entry.isEmpty { return entry }
        if let legacy = UserDefaults.standard.string(forKey: Self.legacyCacheURLKey), !legacy.isEmpty {
            return legacy
        }
        return nil
    }

    public var cachedRouteURL: String? {
        cachedStatus ? preferredCachedURL : nil
    }

    public func isOnline() async -> Bool {
        await NetworkPathProbe.isOnline()
    }

    public func decide(endpoint: String) async -> TrackResult {
        guard await NetworkPathProbe.isOnline() else { return .nativeUI }

        if let url = cachedRouteURL {
            return .experiment(url: url)
        }

        guard let url = URL(string: endpoint) else { return .nativeUI }

        let response = await session.request(
            url,
            method: .post,
            parameters: buildTrackPayload(),
            encoding: JSONEncoding.default
        )
        .validate(statusCode: 200..<300)
        .serializingDecodable(TrackResponse.self)
        .response

        guard let decoded = response.value,
              let experiment = decoded.experiments[AnalyticsTracker.experimentKey],
              experiment.enabled,
              !experiment.url.isEmpty else {
            return .nativeUI
        }

        cachedStatus = true
        cachedEntryURL = experiment.url
        return .experiment(url: cachedFinalURL?.nilIfEmpty ?? experiment.url)
    }

    public var hasFinalURL: Bool {
        cachedFinalURL?.nilIfEmpty != nil
    }

    public func setFinalURLIfNeeded(_ url: String) {
        guard !url.isEmpty, !hasFinalURL else { return }
        cachedFinalURL = url
        UserDefaults.standard.set(url, forKey: Self.legacyCacheURLKey)
    }

    public func clearCache() {
        cachedStatus = false
        cachedEntryURL = nil
        cachedFinalURL = nil
        UserDefaults.standard.removeObject(forKey: Self.legacyCacheURLKey)
    }

    private func buildTrackPayload() -> [String: String] {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        var payload: [String: String] = [
            "device": UIDevice.current.model,
            "os": UIDevice.current.systemVersion,
            "app_version": version,
            "locale": Locale.current.identifier,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "session_id": UUID().uuidString
        ]
        for (key, value) in InstallAttribution.trackFields() {
            payload[key] = value
        }
        return payload
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

struct TrackResponse: Codable {
    let experiments: [String: ExperimentVariant]
}

struct ExperimentVariant: Codable {
    let enabled: Bool
    let url: String
}
