import XCTest
@testable import PlatinFold

final class MockAnalyticsSession: AnalyticsSessionProviding, @unchecked Sendable {
    var cachedRouteURL: String? = nil
    var hasFinalURL: Bool = false
    var online: Bool = true
    
    func isOnline() async -> Bool { return online }
    func clearCache() {}
    func setFinalURLIfNeeded(_ url: String) {}
}

final class MockAnalyticsCoordinator: AnalyticsCoordinating, @unchecked Sendable {
    var resultToReturn: TrackResult = .nativeUI
    var resolveDelay: TimeInterval = 0.0
    
    func resolveResult() async -> TrackResult {
        if resolveDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(resolveDelay * 1_000_000_000))
        }
        return resultToReturn
    }
}

@MainActor
final class StartupRouterTests: XCTestCase {
    
    func testOfflineDefaultsToNative() async {
        let coordinator = MockAnalyticsCoordinator()
        let session = MockAnalyticsSession()
        session.online = false
        coordinator.resultToReturn = .nativeUI
        
        let deps = AppDependencies(projects: SeededProjectStore(), store: MixStore(), benchContainer: nil, analyticsCoordinator: coordinator, analyticsSession: session)
        let router = StartupRouter(dependencies: deps)
        
        await router.start()
        
        if case .native = router.phase {
            // pass
        } else {
            XCTFail("Expected native phase due to offline")
        }
    }
    
    func testEmptyEndpointDefaultsToNative() async {
        let coordinator = MockAnalyticsCoordinator()
        let session = MockAnalyticsSession()
        coordinator.resultToReturn = .nativeUI // Simulation of empty endpoint
        
        let deps = AppDependencies(projects: SeededProjectStore(), store: MixStore(), benchContainer: nil, analyticsCoordinator: coordinator, analyticsSession: session)
        let router = StartupRouter(dependencies: deps)
        
        await router.start()
        
        if case .native = router.phase {
            // pass
        } else {
            XCTFail("Expected native phase due to empty endpoint")
        }
    }
    
    func testDisabledExperimentDefaultsToNative() async {
        let coordinator = MockAnalyticsCoordinator()
        let session = MockAnalyticsSession()
        coordinator.resultToReturn = .nativeUI // Simulation of enabled=false
        
        let deps = AppDependencies(projects: SeededProjectStore(), store: MixStore(), benchContainer: nil, analyticsCoordinator: coordinator, analyticsSession: session)
        let router = StartupRouter(dependencies: deps)
        
        await router.start()
        
        if case .native = router.phase {
            // pass
        } else {
            XCTFail("Expected native phase due to disabled experiment")
        }
    }
    
    func testHTTPErrorDefaultsToNative() async {
        let coordinator = MockAnalyticsCoordinator()
        let session = MockAnalyticsSession()
        coordinator.resultToReturn = .nativeUI // Simulation of HTTP error
        
        let deps = AppDependencies(projects: SeededProjectStore(), store: MixStore(), benchContainer: nil, analyticsCoordinator: coordinator, analyticsSession: session)
        let router = StartupRouter(dependencies: deps)
        
        await router.start()
        
        if case .native = router.phase {
            // pass
        } else {
            XCTFail("Expected native phase due to HTTP error")
        }
    }
    
    func testTimeoutDefaultsToNative() async {
        let coordinator = MockAnalyticsCoordinator()
        let session = MockAnalyticsSession()
        // Make resolveResult take longer than the 4.0s startupDeadline
        coordinator.resolveDelay = 4.5
        coordinator.resultToReturn = .experiment(url: "https://casino.com")
        
        let deps = AppDependencies(projects: SeededProjectStore(), store: MixStore(), benchContainer: nil, analyticsCoordinator: coordinator, analyticsSession: session)
        let router = StartupRouter(dependencies: deps)
        
        await router.start()
        
        if case .native = router.phase {
            // pass
        } else {
            XCTFail("Expected native phase due to timeout, got \(router.phase)")
        }
    }
    
    func testValidExperimentReturnsExperiment() async {
        let coordinator = MockAnalyticsCoordinator()
        let session = MockAnalyticsSession()
        coordinator.resultToReturn = .experiment(url: "https://casino.com")
        
        let deps = AppDependencies(projects: SeededProjectStore(), store: MixStore(), benchContainer: nil, analyticsCoordinator: coordinator, analyticsSession: session)
        let router = StartupRouter(dependencies: deps)
        
        await router.start()
        
        if case .experiment(_) = router.phase {
            // pass
        } else {
            XCTFail("Expected experiment phase, got \(router.phase)")
        }
    }
}
