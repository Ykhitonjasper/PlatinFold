import XCTest
@testable import PlatinFold

final class WebViewControllerURLTests: XCTestCase {
    func testAttributionQuerySurvivesUnchanged() {
        let raw = "https://example.test/path/?ref=6a918336a256a10001818e1b&p=p1ee"

        XCTAssertEqual(WebViewController.resolveURL(from: raw)?.absoluteString, raw)
    }

    func testEncodedParameterIsNotUnwrapped() {
        let raw = "https://example.test/path/?ref=a%2Bb%3D&back=https%3A%2F%2Ffoo.test%2Fx"

        XCTAssertEqual(WebViewController.resolveURL(from: raw)?.absoluteString, raw)
    }

    func testFullyEncodedLinkIsStillDecoded() {
        let raw = "https%3A%2F%2Fexample.test%2Fpath%2F%3Fref%3Dabc"

        XCTAssertEqual(
            WebViewController.resolveURL(from: raw)?.absoluteString,
            "https://example.test/path/?ref=abc"
        )
    }

    func testEmptyStringIsRejected() {
        XCTAssertNil(WebViewController.resolveURL(from: ""))
    }
}
