import XCTest
@testable import ZacksBarCore

final class NativeHostManifestTests: XCTestCase {
    func testManifestUsesExpectedHostNameAndAbsolutePath() throws {
        let manifest = NativeHostManifest(
            path: "/Applications/ZacksBar.app/Contents/MacOS/zacksbar-native-host",
            allowedOrigins: ["chrome-extension://aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/"]
        )
        let data = try JSONEncoder().encode(manifest)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(object?["name"] as? String, "com.zacksbar.native")
        XCTAssertEqual(object?["path"] as? String, "/Applications/ZacksBar.app/Contents/MacOS/zacksbar-native-host")
        XCTAssertEqual(object?["allowed_origins"] as? [String], ["chrome-extension://aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/"])
    }
}
