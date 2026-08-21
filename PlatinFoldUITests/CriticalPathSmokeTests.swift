import XCTest

final class CriticalPathSmokeTests: XCTestCase {
    private static let onboardingCTAs = ["Next", "Continue", "Get started", "Get Started", "Start", "Begin", "Let's go", "Done"]
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testCriticalInteractions() {
        completeOnboarding()
        let control1 = element("smoke.mix.openDilute")
        XCTAssertTrue(control1.waitForExistence(timeout: 8), "Critical control 1 is unavailable")
        XCTAssertFalse(element("smoke.mix.diluteCard").exists, "Critical result 1 already exists before its action")
        control1.tap()
        XCTAssertTrue(element("smoke.mix.diluteCard").waitForExistence(timeout: 8), "Critical result 1 did not appear")
        let control2 = element("smoke.mix.showLines")
        XCTAssertTrue(control2.waitForExistence(timeout: 8), "Critical control 2 is unavailable")
        XCTAssertFalse(element("smoke.mix.tankLines").exists, "Critical result 2 already exists before its action")
        control2.tap()
        XCTAssertTrue(element("smoke.mix.tankLines").waitForExistence(timeout: 8), "Critical result 2 did not appear")
        let control3 = element("smoke.mix.saveMix")
        XCTAssertTrue(control3.waitForExistence(timeout: 8), "Critical control 3 is unavailable")
        XCTAssertFalse(element("smoke.mix.saveSheet").exists, "Critical result 3 already exists before its action")
        control3.tap()
        XCTAssertTrue(element("smoke.mix.saveSheet").waitForExistence(timeout: 8), "Critical result 3 did not appear")
        XCTAssertEqual(app.state, .runningForeground, "App left the foreground during critical interactions")
    }

    private func completeOnboarding() {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15), "App never reached the foreground")
        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 10)
        settle()
        for _ in 0..<8 {
            if app.tabBars.firstMatch.exists { break }
            guard let button = onboardingButton() else { break }
            button.tap()
            settle(0.5)
        }
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 8), "Onboarding did not reach the main surface")
    }

    private func onboardingButton() -> XCUIElement? {
        for title in Self.onboardingCTAs {
            let button = app.buttons[title]
            if button.exists && button.isHittable { return button }
        }
        // No "single hittable button" fallback: a niche-worded hero has one CTA
        // ("Pick tonight") and the fallback used to press it, letting the smoke
        // tap into the primary flow while pretending it was still onboarding.
        return nil
    }

    private func settle(_ seconds: TimeInterval = 0.8) {
        _ = XCTWaiter().wait(for: [XCTestExpectation(description: "settle")], timeout: seconds)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}
