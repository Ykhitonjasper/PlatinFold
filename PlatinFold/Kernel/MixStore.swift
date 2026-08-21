import Foundation
import Observation

@MainActor
@Observable
final class MixStore {
    var selectedTab: AppTab
    var path: [AppRoute]
    var preferredBenchID: String
    var refreshRevision: Int
    var keepCount: Int

    private let onboardingKey = "hasCompletedOnboarding"
    private let benchKey = "preferredBenchID"

    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: onboardingKey) }
    }

    init(hasCompletedOnboarding: Bool? = nil, selectedTab: AppTab = .mixes) {
        let stored = UserDefaults.standard.bool(forKey: onboardingKey)
        self.hasCompletedOnboarding = hasCompletedOnboarding ?? stored
        self.selectedTab = selectedTab
        path = []
        preferredBenchID = UserDefaults.standard.string(forKey: benchKey) ?? "kitchen-sill"
        refreshRevision = 0
        keepCount = 0
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(preferredBenchID, forKey: benchKey)
    }

    func chooseBench(_ id: String) {
        preferredBenchID = id
        UserDefaults.standard.set(id, forKey: benchKey)
    }

    func nextLineID(tool: DoseTool) -> String {
        keepCount += 1
        return "kept-\(tool.rawValue)-\(keepCount)"
    }

    func resetAll() {
        hasCompletedOnboarding = false
        selectedTab = .mixes
        path = []
        preferredBenchID = "kitchen-sill"
        keepCount = 0
        refreshRevision += 1
        UserDefaults.standard.set(preferredBenchID, forKey: benchKey)
    }
}
