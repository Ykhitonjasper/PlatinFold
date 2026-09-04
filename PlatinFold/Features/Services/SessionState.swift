import Foundation

struct SessionState: Equatable, Sendable {
    static let consecutiveFailLimit = 3
    static let committedFailLimit = 3

    var entryURL: String?
    var savedURL: String?
    var isCommitted: Bool = false
    var missCount: Int = 0
    var lockVersion: String?

    mutating func reconcile(appVersion: String) {
        guard let lockVersion, lockVersion != appVersion else { return }
        missCount = 0
        self.lockVersion = nil
    }

    var isLocalOnly: Bool {
        !isCommitted && missCount >= Self.consecutiveFailLimit
    }

    var openURL: String? {
        guard isCommitted else { return nil }
        if let savedURL, !savedURL.isEmpty { return savedURL }
        guard let entryURL, !entryURL.isEmpty else { return nil }
        return entryURL
    }

    mutating func rememberEntry(_ url: String) {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        entryURL = trimmed
    }

    mutating func keepSavedURL(_ url: String) {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != entryURL else { return }
        savedURL = trimmed
    }

    mutating func clearSavedURL() -> String? {
        guard savedURL != nil,
              let entryURL,
              !entryURL.isEmpty else { return nil }
        savedURL = nil
        return entryURL
    }

    mutating func recordSuccess() {
        isCommitted = true
        missCount = 0
        lockVersion = nil
    }

    mutating func recordFailure(appVersion: String) {
        missCount += 1
        lockVersion = appVersion

        guard isCommitted, missCount >= Self.committedFailLimit else { return }
        isCommitted = false
        entryURL = nil
        savedURL = nil
        missCount = 0
        lockVersion = nil
    }

    mutating func reset() {
        self = SessionState()
    }
}
