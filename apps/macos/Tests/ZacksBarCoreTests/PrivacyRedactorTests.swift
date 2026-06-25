import XCTest
@testable import ZacksBarCore

final class PrivacyRedactorTests: XCTestCase {
    func testRedactsQueryPhoneAndOrderNumber() {
        let input = "https://example.com/path?token=abc 13800138000 order 202606250001"
        let output = PrivacyRedactor.redact(input)
        XCTAssertFalse(output.contains("token=abc"))
        XCTAssertFalse(output.contains("13800138000"))
        XCTAssertFalse(output.contains("202606250001"))
    }
}
