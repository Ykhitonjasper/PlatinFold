import XCTest
@testable import PlatinFold

final class SessionStateTests: XCTestCase {
    private let version = "1.0.1"
    private let entry = "https://example.test/go"
    private let settled = "https://offer.test/land?ref=abc"

    func testSuccessCommitsEntryAndClearsFails() {
        var policy = SessionState()
        policy.rememberEntry(entry)
        policy.recordFailure(appVersion: version)
        policy.recordSuccess()

        XCTAssertTrue(policy.isCommitted)
        XCTAssertEqual(policy.openURL, entry)
        XCTAssertEqual(policy.missCount, 0)
        XCTAssertFalse(policy.isLocalOnly)
    }

    func testCommittedRoutePrefersSettledOverEntry() {
        var policy = SessionState()
        policy.rememberEntry(entry)
        policy.recordSuccess()
        policy.keepSavedURL(settled)

        XCTAssertEqual(policy.openURL, settled)
    }

    func testPendingEntryDoesNotRouteUntilSuccess() {
        var policy = SessionState()
        policy.rememberEntry(entry)

        XCTAssertNil(policy.openURL)
        XCTAssertFalse(policy.isCommitted)
        XCTAssertFalse(policy.isLocalOnly)
    }

    func testThreeFailuresLockUntilVersionChanges() {
        var policy = SessionState()
        policy.rememberEntry(entry)
        policy.recordFailure(appVersion: version)
        policy.recordFailure(appVersion: version)
        XCTAssertFalse(policy.isLocalOnly)

        policy.recordFailure(appVersion: version)
        XCTAssertTrue(policy.isLocalOnly)
        XCTAssertEqual(policy.lockVersion, version)
        XCTAssertNil(policy.openURL)

        policy.reconcile(appVersion: "1.0.2")
        XCTAssertFalse(policy.isLocalOnly)
        XCTAssertEqual(policy.missCount, 0)
        XCTAssertNil(policy.lockVersion)
    }

    func testPartialFailCounterResetsOnVersionBump() {
        var policy = SessionState()
        policy.rememberEntry(entry)
        policy.recordFailure(appVersion: version)
        policy.recordFailure(appVersion: version)

        policy.reconcile(appVersion: "1.0.2")
        XCTAssertEqual(policy.missCount, 0)

        policy.recordFailure(appVersion: "1.0.2")
        XCTAssertFalse(policy.isLocalOnly)
    }

    func testCommittedRouteSurvivesOccasionalFailures() {
        var policy = SessionState()
        policy.rememberEntry(entry)
        policy.recordSuccess()
        policy.recordFailure(appVersion: version)
        policy.recordFailure(appVersion: version)

        XCTAssertTrue(policy.isCommitted)
        XCTAssertFalse(policy.isLocalOnly)
        XCTAssertEqual(policy.openURL, entry)
    }

    func testCommittedRouteIsDroppedAfterRepeatedFailures() {
        var policy = SessionState()
        policy.rememberEntry(entry)
        policy.recordSuccess()
        policy.recordFailure(appVersion: version)
        policy.recordFailure(appVersion: version)
        policy.recordFailure(appVersion: version)

        XCTAssertFalse(policy.isCommitted)
        XCTAssertNil(policy.openURL)
        XCTAssertFalse(policy.isLocalOnly)
        XCTAssertEqual(policy.missCount, 0)
    }

    func testSuccessBetweenFailuresKeepsCommittedRoute() {
        var policy = SessionState()
        policy.rememberEntry(entry)
        policy.recordSuccess()
        policy.recordFailure(appVersion: version)
        policy.recordFailure(appVersion: version)
        policy.recordSuccess()
        policy.recordFailure(appVersion: version)

        XCTAssertTrue(policy.isCommitted)
        XCTAssertEqual(policy.openURL, entry)
    }

    func testDroppedSettledFallsBackToEntryAndKeepsCommit() {
        var policy = SessionState()
        policy.rememberEntry(entry)
        policy.recordSuccess()
        policy.keepSavedURL(settled)

        XCTAssertEqual(policy.clearSavedURL(), entry)
        XCTAssertTrue(policy.isCommitted)
        XCTAssertEqual(policy.openURL, entry)
        XCTAssertEqual(policy.missCount, 0)
    }

    func testDropSettledReportsNothingToRetryWhenNoneCached() {
        var policy = SessionState()
        policy.rememberEntry(entry)
        policy.recordSuccess()

        XCTAssertNil(policy.clearSavedURL())
        XCTAssertEqual(policy.openURL, entry)
    }

    func testSettledKeepsQuery() {
        let attributed = "https://example.test/path/?ref=6a918336a256a10001818e1b&p=p1ee"
        var policy = SessionState()
        policy.rememberEntry(entry)
        policy.recordSuccess()
        policy.keepSavedURL(attributed)

        XCTAssertEqual(policy.openURL, attributed)
    }

    func testSettledMatchingEntryIsNotStored() {
        var policy = SessionState()
        policy.rememberEntry(entry)
        policy.recordSuccess()
        policy.keepSavedURL(entry)

        XCTAssertNil(policy.savedURL)
        XCTAssertNil(policy.clearSavedURL())
    }

    func testRepeatedFailuresClearSettledAlongWithCommit() {
        var policy = SessionState()
        policy.rememberEntry(entry)
        policy.recordSuccess()
        policy.keepSavedURL(settled)
        policy.recordFailure(appVersion: version)
        policy.recordFailure(appVersion: version)
        policy.recordFailure(appVersion: version)

        XCTAssertFalse(policy.isCommitted)
        XCTAssertNil(policy.savedURL)
        XCTAssertNil(policy.entryURL)
        XCTAssertNil(policy.openURL)
    }

    func testResetClearsLockAndCommit() {
        var policy = SessionState()
        policy.rememberEntry(entry)
        policy.recordFailure(appVersion: version)
        policy.recordFailure(appVersion: version)
        policy.recordFailure(appVersion: version)
        policy.reset()

        XCTAssertEqual(policy, SessionState())
    }
}
