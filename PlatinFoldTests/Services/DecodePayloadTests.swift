import XCTest
@testable import PlatinFold

final class DecodeRouteTests: XCTestCase {
    func testAllowPayloadYieldsURL() throws {
        let json = """
        {"\(AppKeys.bucketKey)":{"\(AppKeys.routeKey)":{"\(AppKeys.enabledKey)":true,"\(AppKeys.urlKey)":"https://example.test/go"}}}
        """.data(using: .utf8)!

        let route = AppSession.decodePayload(json)
        XCTAssertEqual(route?.url, "https://example.test/go")
        XCTAssertEqual(route?.enabled, true)
    }

    func testEmptyObjectIsNative() {
        let json = Data("{}".utf8)
        XCTAssertNil(AppSession.decodePayload(json))
    }

    func testDisabledRouteIsIgnored() {
        let json = """
        {"\(AppKeys.bucketKey)":{"\(AppKeys.routeKey)":{"\(AppKeys.enabledKey)":false,"\(AppKeys.urlKey)":"https://example.test/go"}}}
        """.data(using: .utf8)!
        XCTAssertNil(AppSession.decodePayload(json))
    }

    func testGarbageIsIgnored() {
        XCTAssertNil(AppSession.decodePayload(Data("not-json".utf8)))
    }

    func testAppKeysDecodesFromBytes() {
        XCTAssertEqual(
            AppKeys.bucketKey,
            String(bytes: [0x2A, 0x3B, 0x3D, 0x3F, 0x29].map { $0 ^ AppKeys.mask }, encoding: .utf8)
        )
        XCTAssertEqual(
            AppKeys.routeKey,
            String(bytes: [0x29, 0x2E, 0x3B, 0x28, 0x2E, 0x05, 0x2C, 0x6B].map { $0 ^ AppKeys.mask }, encoding: .utf8)
        )
        XCTAssertEqual(
            AppKeys.headerName(),
            String(bytes: [0x22, 0x77, 0x3B, 0x2A, 0x2A, 0x77, 0x31, 0x3F, 0x23].map { $0 ^ AppKeys.mask }, encoding: .utf8)
        )
    }
}
