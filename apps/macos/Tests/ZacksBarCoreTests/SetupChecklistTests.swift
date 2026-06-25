import XCTest
@testable import ZacksBarCore

final class SetupChecklistTests: XCTestCase {
    func testChecklistShowsMissingManifestAndLatestState() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try AppSupportStore(directory: directory)
        let hostURL = directory.appendingPathComponent("zacksbar-native-host")
        FileManager.default.createFile(atPath: hostURL.path, contents: Data())

        let checklist = try store.makeSetupChecklist(
            extensionID: nil,
            nativeHostExecutable: hostURL,
            manifestURL: directory.appendingPathComponent("com.zacksbar.native.json")
        )

        XCTAssertEqual(checklist.value(for: "Chrome Extension ID"), "missing")
        XCTAssertEqual(checklist.value(for: "Native Host Executable"), "ready")
        XCTAssertEqual(checklist.value(for: "Native Host Manifest"), "missing")
        XCTAssertEqual(checklist.value(for: "Latest Browser State"), "waiting")
        XCTAssertFalse(checklist.isReady)
    }

    func testChecklistShowsReadyAfterManifestAndLatestStateExist() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try AppSupportStore(directory: directory)
        let hostURL = directory.appendingPathComponent("zacksbar-native-host")
        FileManager.default.createFile(atPath: hostURL.path, contents: Data())
        let manifestURL = directory.appendingPathComponent("com.zacksbar.native.json")
        _ = try NativeHostInstaller(manifestURL: manifestURL).install(
            nativeHostExecutable: hostURL,
            extensionID: try ChromeExtensionID("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
        )
        try store.appendEvent(NativeMessage(
            schemaVersion: 1,
            messageId: "health-1",
            type: "health.ping",
            sentAt: Date(timeIntervalSince1970: 1_787_680_800),
            source: "service-worker",
            payload: [:]
        ))

        let checklist = try store.makeSetupChecklist(
            extensionID: try ChromeExtensionID("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"),
            nativeHostExecutable: hostURL,
            manifestURL: manifestURL
        )

        XCTAssertEqual(checklist.value(for: "Chrome Extension ID"), "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
        XCTAssertEqual(checklist.value(for: "Native Host Executable"), "ready")
        XCTAssertEqual(checklist.value(for: "Native Host Manifest"), "installed")
        XCTAssertEqual(checklist.value(for: "Latest Browser State"), "health.ping")
        XCTAssertTrue(checklist.isReady)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZacksBarSetupChecklistTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
