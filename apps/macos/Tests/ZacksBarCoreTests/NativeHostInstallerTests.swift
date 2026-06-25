import XCTest
@testable import ZacksBarCore

final class NativeHostInstallerTests: XCTestCase {
    func testChromeExtensionIDValidation() throws {
        XCTAssertNoThrow(try ChromeExtensionID("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"))
        XCTAssertThrowsError(try ChromeExtensionID("short"))
        XCTAssertThrowsError(try ChromeExtensionID("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"))
        XCTAssertThrowsError(try ChromeExtensionID("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1"))
    }

    func testDevelopmentCompanionExtensionIDMatchesManifestKey() {
        XCTAssertEqual(
            ChromeExtensionID.zacksBarCompanionDevelopment.rawValue,
            "nfcmelgclmhkneckkebppdnmbnjpjlho"
        )
    }

    func testInstallWritesManifestWithAllowedOrigin() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZacksBarInstallerTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let manifestURL = directory.appendingPathComponent("com.zacksbar.native.json")
        let hostURL = directory.appendingPathComponent("zacksbar-native-host")
        FileManager.default.createFile(atPath: hostURL.path, contents: Data())
        let installer = NativeHostInstaller(manifestURL: manifestURL)

        let result = try installer.install(
            nativeHostExecutable: hostURL,
            extensionID: try ChromeExtensionID("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
        )

        XCTAssertEqual(result.manifestURL, manifestURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: manifestURL.path))

        let data = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(NativeHostManifest.self, from: data)
        XCTAssertEqual(manifest.name, "com.zacksbar.native")
        XCTAssertEqual(manifest.path, hostURL.path)
        XCTAssertEqual(manifest.allowedOrigins, ["chrome-extension://aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/"])
    }
}
