import SwiftUI
import XCTest
@testable import PlatinFold

@MainActor
final class AppCoverTests: XCTestCase {
    func testScenePhaseCoverLiftsOnReturn() {
        let manager = AppCover()

        manager.handleScenePhase(.inactive)
        XCTAssertTrue(manager.isCoverVisible)

        manager.handleScenePhase(.active)
        XCTAssertFalse(manager.isCoverVisible)
    }

    func testBackgroundCoverLiftsOnReturn() {
        let manager = AppCover()

        manager.handleScenePhase(.background)
        XCTAssertTrue(manager.isCoverVisible)

        manager.handleScenePhase(.active)
        XCTAssertFalse(manager.isCoverVisible)
    }

    func testTapLiftsCoverWhileInactive() {
        let manager = AppCover()

        manager.handleScenePhase(.inactive)
        XCTAssertTrue(manager.isCoverVisible)

        manager.deactivateImmediately()
        XCTAssertFalse(manager.isCoverVisible)
    }
}
