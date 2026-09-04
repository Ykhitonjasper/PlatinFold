import Alamofire
import Foundation
import Network
import UIKit

final class OneShotContinuation<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, Never>?

    init(_ continuation: CheckedContinuation<Value, Never>) {
        self.continuation = continuation
    }

    func resume(_ value: Value) {
        _ = tryResume(value)
    }

    /// Reports whether this call was the one that delivered the value, which
    /// lets a loser of a race notice that it arrived too late.
    @discardableResult
    func tryResume(_ value: Value) -> Bool {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(returning: value)
        return pending != nil
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

        DispatchQueue.global().asyncAfter(deadline: .now() + Timeouts.networkProbeTimeout) { [weak self] in
            self?.finish(false)
        }
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

public protocol AppSessionType: Sendable {
    var cachedURL: String? { get }
    var isLocalOnly: Bool { get }
    var launchCount: Int { get }
    func isOnline() async -> Bool
    func refreshOnline() async -> Bool
    func resolve(url: String) async -> LoadResult
    func markReady()
    func markMiss()
    func storeDestination(_ url: String)
    func clearURLForRetry() -> String?
    func recordLaunch()
}

public final class AppSession: NSObject, @unchecked Sendable {
    public static let shared = AppSession()

    private let defaults: UserDefaults
    private let appVersion: String
    private let lock = NSLock()
    private let session: Session
    private var onlineProbe: (value: Bool, at: Date)?

    private override init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Timeouts.networkTimeout
        configuration.timeoutIntervalForResource = Timeouts.networkTimeout
        self.session = Session(configuration: configuration)
        self.defaults = .standard
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        super.init()
        migrateLegacyStorageIfNeeded()
    }

    /// Runs once per install: the marker has to outlive the keys it reads,
    /// otherwise a later wipe would be undone on the next launch.
    private func migrateLegacyStorageIfNeeded() {
        lock.lock()
        defer { lock.unlock() }

        guard !defaults.bool(forKey: AppKeys.migratedKey) else { return }
        defaults.set(true, forKey: AppKeys.migratedKey)

        if let legacy = defaults.string(forKey: AppKeys.legacyCacheURLKey)?.nilIfEmpty {
            if defaults.string(forKey: AppKeys.cacheFinalKey)?.nilIfEmpty == nil {
                defaults.set(legacy, forKey: AppKeys.cacheFinalKey)
            }
            defaults.removeObject(forKey: AppKeys.legacyCacheURLKey)
        }

        guard defaults.string(forKey: AppKeys.cacheFinalKey)?.nilIfEmpty != nil,
              defaults.bool(forKey: AppKeys.cacheStatusKey) else { return }
        defaults.set(true, forKey: AppKeys.committedKey)
    }

    public var isLocalOnly: Bool {
        lock.lock()
        defer { lock.unlock() }
        return loadPolicyLocked().isLocalOnly
    }

    public var cachedURL: String? {
        lock.lock()
        defer { lock.unlock() }
        return loadPolicyLocked().openURL
    }

    public var launchCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return defaults.integer(forKey: AppKeys.launchCountKey)
    }

    public func recordLaunch() {
        lock.lock()
        defer { lock.unlock() }
        let next = defaults.integer(forKey: AppKeys.launchCountKey) + 1
        defaults.set(next, forKey: AppKeys.launchCountKey)
    }

    public func isOnline() async -> Bool {
        lock.lock()
        let cached = onlineProbe
        lock.unlock()
        if let cached, Date().timeIntervalSince(cached.at) < Timeouts.networkProbeCacheTTL {
            return cached.value
        }

        let value = await NetworkPathProbe.isOnline()

        lock.lock()
        onlineProbe = (value, Date())
        lock.unlock()
        return value
    }

    /// Fresh path check — used after a probe miss so a stale "online" cache
    /// cannot force a blank WKWebView under airplane mode.
    public func refreshOnline() async -> Bool {
        lock.lock()
        onlineProbe = nil
        lock.unlock()
        return await isOnline()
    }

    public func resolve(url: String) async -> LoadResult {
        if isLocalOnly { return .local }
        guard await isOnline() else { return .local }

        if let cached = cachedURL {
            return .web(url: cached)
        }

        guard let requestURL = URL(string: url) else { return .local }

        let response = await session.request(
            requestURL,
            method: .post,
            parameters: buildPayload(),
            encoding: JSONEncoding.default,
            headers: AppConfig.headers
        )
        .validate(statusCode: 200..<300)
        .serializingData()
        .response

        guard let data = response.data,
              let route = Self.decodePayload(data) else {
            return .local
        }

        rememberEntry(route.url)
        return .web(url: route.url)
    }

    static func decodePayload(_ data: Data) -> PageInfo? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let bucket = root[AppKeys.bucketKey] as? [String: Any],
              let entry = bucket[AppKeys.routeKey] as? [String: Any] else {
            return nil
        }

        let enabled: Bool
        if let flag = entry[AppKeys.enabledKey] as? Bool {
            enabled = flag
        } else if let number = entry[AppKeys.enabledKey] as? NSNumber {
            enabled = number.boolValue
        } else {
            return nil
        }

        guard enabled,
              let url = entry[AppKeys.urlKey] as? String,
              !url.isEmpty else {
            return nil
        }
        return PageInfo(enabled: true, url: url)
    }

    public func markReady() {
        mutatePolicy { policy in
            policy.recordSuccess()
        }
    }

    public func markMiss() {
        mutatePolicy { policy in
            policy.recordFailure(appVersion: appVersion)
        }
    }

    public func storeDestination(_ url: String) {
        mutatePolicy { policy in
            policy.keepSavedURL(url)
        }
    }

    public func clearURLForRetry() -> String? {
        lock.lock()
        defer { lock.unlock() }
        let current = loadPolicyLocked()
        var updated = current
        let retry = updated.clearSavedURL()
        if updated != current { savePolicyLocked(updated) }
        return retry
    }

    private func rememberEntry(_ url: String) {
        mutatePolicy { policy in
            policy.rememberEntry(url)
        }
    }

    private func mutatePolicy(_ body: (inout SessionState) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        let current = loadPolicyLocked()
        var updated = current
        body(&updated)
        guard updated != current else { return }
        savePolicyLocked(updated)
    }

    private func loadPolicyLocked() -> SessionState {
        var policy = SessionState(
            entryURL: defaults.string(forKey: AppKeys.cacheEntryKey),
            savedURL: defaults.string(forKey: AppKeys.cacheFinalKey),
            isCommitted: defaults.bool(forKey: AppKeys.committedKey),
            missCount: defaults.integer(forKey: AppKeys.missCountKey),
            lockVersion: defaults.string(forKey: AppKeys.lockVersionKey)
        )
        policy.reconcile(appVersion: appVersion)
        return policy
    }

    private func savePolicyLocked(_ policy: SessionState) {
        defaults.set(policy.isCommitted, forKey: AppKeys.committedKey)
        defaults.set(policy.missCount, forKey: AppKeys.missCountKey)

        if let entry = policy.entryURL, !entry.isEmpty {
            defaults.set(entry, forKey: AppKeys.cacheEntryKey)
        } else {
            defaults.removeObject(forKey: AppKeys.cacheEntryKey)
        }

        if let settled = policy.savedURL, !settled.isEmpty {
            defaults.set(settled, forKey: AppKeys.cacheFinalKey)
        } else {
            defaults.removeObject(forKey: AppKeys.cacheFinalKey)
        }

        if let lockVersion = policy.lockVersion, !lockVersion.isEmpty {
            defaults.set(lockVersion, forKey: AppKeys.lockVersionKey)
        } else {
            defaults.removeObject(forKey: AppKeys.lockVersionKey)
        }
    }

    private func buildPayload() -> [String: String] {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        var payload: [String: String] = [
            "device": UIDevice.current.model,
            "os": UIDevice.current.systemVersion,
            "app_version": version,
            "locale": Locale.current.identifier,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "session_id": UUID().uuidString
        ]
        for (key, value) in DeviceInfo.extraFields() {
            payload[key] = value
        }
        return payload
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

extension AppSession: AppSessionType {}

