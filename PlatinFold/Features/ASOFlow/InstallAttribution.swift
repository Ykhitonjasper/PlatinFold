import Foundation
import AdServices

enum InstallAttribution {
    private static let installIDKey = "install_id_v1"
    private static let asaTokenKey = "asa_token_v1"
    private static let asaCapturedAtKey = "asa_token_at_v1"

    static var installID: String {
        if let existing = UserDefaults.standard.string(forKey: installIDKey), !existing.isEmpty {
            return existing
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: installIDKey)
        return id
    }

    static var cachedASAToken: String? {
        UserDefaults.standard.string(forKey: asaTokenKey)?.nilIfEmpty
    }

    static func asaAttributionToken() -> String {
        if let cached = cachedASAToken {
            return cached
        }

        #if targetEnvironment(simulator)
        return ""
        #else
        do {
            let token = try AAAttribution.attributionToken()
            guard !token.isEmpty else { return "" }
            UserDefaults.standard.set(token, forKey: asaTokenKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: asaCapturedAtKey)
            return token
        } catch {
            return ""
        }
        #endif
    }

    static func trackFields() -> [String: String] {
        let token = asaAttributionToken()
        return [
            "install_id": installID,
            "asa_token": token,
            "attribution_source": token.isEmpty ? "unknown_or_organic" : "apple_search_ads"
        ]
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
