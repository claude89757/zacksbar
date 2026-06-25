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
        XCTAssertEqual(checklist.value(for: "Browser Companion"), "waiting")
        XCTAssertEqual(checklist.value(for: "Pending Browser Commands"), "0 pending")
        XCTAssertEqual(checklist.value(for: "Parser Diagnostics"), "waiting")
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
            payload: [
                "component": .string("zacksbar-companion"),
                "version": .string("0.1.0")
            ]
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
        XCTAssertEqual(checklist.value(for: "Browser Companion"), "0.1.0")
        XCTAssertEqual(checklist.value(for: "Pending Browser Commands"), "0 pending")
        XCTAssertEqual(checklist.value(for: "Parser Diagnostics"), "waiting")
        XCTAssertFalse(checklist.isReady)
    }

    func testChecklistShowsParserDiagnosticsWhenParserMessageExists() throws {
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
            sentAt: Date(timeIntervalSince1970: 1_787_680_700),
            source: "service-worker",
            payload: [
                "component": .string("zacksbar-companion"),
                "version": .string("0.1.0")
            ]
        ))
        try store.appendEvent(NativeMessage(
            schemaVersion: 1,
            messageId: "parser-1",
            type: "parser.diagnostics",
            sentAt: Date(timeIntervalSince1970: 1_787_680_800),
            source: "content-script",
            payload: [
                "scheduleTableFound": .bool(true),
                "slotCount": .number(8)
            ]
        ))

        let checklist = try store.makeSetupChecklist(
            extensionID: try ChromeExtensionID("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"),
            nativeHostExecutable: hostURL,
            manifestURL: manifestURL
        )

        XCTAssertEqual(checklist.value(for: "Latest Browser State"), "parser.diagnostics")
        XCTAssertEqual(checklist.value(for: "Browser Companion"), "0.1.0")
        XCTAssertEqual(checklist.value(for: "Pending Browser Commands"), "0 pending")
        XCTAssertEqual(checklist.value(for: "Parser Diagnostics"), "8 slots")
        XCTAssertTrue(checklist.isReady)
    }

    func testChecklistShowsPendingBrowserCommands() throws {
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
            sentAt: Date(timeIntervalSince1970: 1_787_680_700),
            source: "service-worker",
            payload: [
                "component": .string("zacksbar-companion"),
                "version": .string("0.1.0")
            ]
        ))
        try store.appendEvent(NativeMessage(
            schemaVersion: 1,
            messageId: "parser-1",
            type: "parser.diagnostics",
            sentAt: Date(timeIntervalSince1970: 1_787_680_800),
            source: "content-script",
            payload: [
                "scheduleTableFound": .bool(true),
                "slotCount": .number(8)
            ]
        ))
        try store.appendCommand(NativeMessage(
            schemaVersion: 1,
            messageId: "command-1",
            type: "extension.reload",
            sentAt: Date(timeIntervalSince1970: 1_787_680_900),
            source: "zacksbar-app",
            payload: [:]
        ))

        let checklist = try store.makeSetupChecklist(
            extensionID: try ChromeExtensionID("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"),
            nativeHostExecutable: hostURL,
            manifestURL: manifestURL
        )

        XCTAssertEqual(checklist.value(for: "Pending Browser Commands"), "1 pending: extension.reload")
        XCTAssertFalse(checklist.isReady)
    }

    func testChecklistShowsMismatchedBrowserCompanionVersion() throws {
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
            payload: [
                "component": .string("zacksbar-companion"),
                "version": .string("0.0.9")
            ]
        ))

        let checklist = try store.makeSetupChecklist(
            extensionID: try ChromeExtensionID("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"),
            nativeHostExecutable: hostURL,
            manifestURL: manifestURL,
            expectedCompanionVersion: "0.1.0"
        )

        XCTAssertEqual(checklist.value(for: "Latest Browser State"), "health.ping")
        XCTAssertEqual(checklist.value(for: "Browser Companion"), "reload 0.0.9 -> 0.1.0")
        XCTAssertFalse(checklist.isReady)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZacksBarSetupChecklistTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
