import Foundation
import AdServices

enum DeviceInfo {
    private static let gate = NSLock()
    private static var prefetchStarted = false

    static var installID: String {
        let key = AppKeys.installIDStorageKey
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: key)
        return id
    }

    static var cachedASAToken: String? {
        UserDefaults.standard.string(forKey: AppKeys.asaTokenStorageKey)?.nilIfEmpty
    }

    /// Overlaps the synchronous ASA call with decide so a cold token does not
    /// steal time from the launch window.
    static func prefetchAttributionToken() {
        #if targetEnvironment(simulator)
        return
        #else
        gate.lock()
        if prefetchStarted || cachedASAToken != nil {
            gate.unlock()
            return
        }
        prefetchStarted = true
        gate.unlock()

        DispatchQueue.global(qos: .utility).async {
            _ = adsToken()
        }
        #endif
    }

    static func adsToken() -> String {
        if let cached = cachedASAToken {
            return cached
        }

        #if targetEnvironment(simulator)
        return ""
        #else
        do {
            let token = try AAAttribution.attributionToken()
            guard !token.isEmpty else { return "" }
            UserDefaults.standard.set(token, forKey: AppKeys.asaTokenStorageKey)
            return token
        } catch {
            return ""
        }
        #endif
    }

    static func extraFields() -> [String: String] {
        let token = adsToken()
        return [
            AppKeys.installIDField: installID,
            AppKeys.asaTokenField: token,
            AppKeys.attributionSourceField: token.isEmpty
                ? AppKeys.fallbackSourceValue
                : AppKeys.appleSearchAdsValue
        ]
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
