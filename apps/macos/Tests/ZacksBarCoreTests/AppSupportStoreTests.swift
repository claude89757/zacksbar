import XCTest
@testable import ZacksBarCore

final class AppSupportStoreTests: XCTestCase {
    func testAppendAvailabilityUpdatesLatestState() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZacksBarStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = try AppSupportStore(directory: directory)
        let message = NativeMessage(
            schemaVersion: 1,
            messageId: "availability-1",
            type: "availability.updated",
            sentAt: Date(timeIntervalSince1970: 1_787_680_800),
            source: "content-script",
            payload: [
                "venue": .string("宝安网球馆"),
                "dateLabel": .string("6-26"),
                "slots": .array([
                    .object([
                        "courtId": .string("court-1"),
                        "start": .string("19:00"),
                        "end": .string("20:00"),
                        "available": .bool(true)
                    ])
                ])
            ]
        )

        try store.appendEvent(message)

        let state = try XCTUnwrap(store.readLatestState())
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.latestStateFile.path))
        XCTAssertEqual(state.latestMessageType, "availability.updated")
        XCTAssertEqual(state.latestAvailability?.payload["venue"]?.stringValue, "宝安网球馆")
        XCTAssertNil(state.latestCaptcha)
    }

    func testAppendParserDiagnosticsUpdatesLatestState() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZacksBarStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = try AppSupportStore(directory: directory)
        let message = NativeMessage(
            schemaVersion: 1,
            messageId: "parser-1",
            type: "parser.diagnostics",
            sentAt: Date(timeIntervalSince1970: 1_787_680_800),
            source: "content-script",
            payload: [
                "vueRootFound": .bool(true),
                "scheduleTableFound": .bool(true),
                "rowCount": .number(2),
                "slotCount": .number(8),
                "availableSlotCount": .number(1)
            ]
        )

        try store.appendEvent(message)

        let state = try XCTUnwrap(store.readLatestState())
        XCTAssertEqual(state.latestMessageType, "parser.diagnostics")
        XCTAssertEqual(state.latestParserDiagnostics?.payload["slotCount"], .number(8))
        XCTAssertNil(state.latestAvailability)
    }

    func testReadWatchRulesReturnsDefaultWhenFileIsMissing() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZacksBarStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = try AppSupportStore(directory: directory)

        let rules = try store.readWatchRules()

        XCTAssertEqual(rules, [
            WatchRule(id: "default-evening", dateMode: .latestBookable, start: "19:00", end: "21:00", courtKeywords: [])
        ])
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.watchRulesFile.path))
    }

    func testWriteAndReadWatchRulesRoundTrips() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZacksBarStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = try AppSupportStore(directory: directory)
        let rule = WatchRule(
            id: "custom-evening",
            dateMode: .tomorrow,
            start: "18:00",
            end: "20:00",
            courtKeywords: ["1号"]
        )

        try store.writeWatchRules([rule])

        XCTAssertTrue(FileManager.default.fileExists(atPath: store.watchRulesFile.path))
        XCTAssertEqual(try store.readWatchRules(), [rule])
    }

    func testAppendAndDrainCommandsRoundTripsInOrder() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZacksBarStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = try AppSupportStore(directory: directory)
        let reload = commandMessage(id: "command-1", type: "extension.reload")
        let tabOpen = commandMessage(id: "command-2", type: "tab.open")

        try store.appendCommand(reload)
        try store.appendCommand(tabOpen)

        XCTAssertTrue(FileManager.default.fileExists(atPath: store.commandsFile.path))
        XCTAssertEqual(try store.drainCommands(), [reload, tabOpen])
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.commandsFile.path))
        XCTAssertEqual(try store.drainCommands(), [])
    }

    func testDrainCommandsSkipsMalformedLines() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZacksBarStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = try AppSupportStore(directory: directory)
        let valid = commandMessage(id: "command-1", type: "extension.reload")
        var contents = Data("not-json\n".utf8)
        contents.append(try JSONEncoder.zacksBar.encode(valid))
        contents.append(Data("\n".utf8))
        try contents.write(to: store.commandsFile)

        XCTAssertEqual(try store.drainCommands(), [valid])
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.commandsFile.path))
    }

    func testReadPendingCommandsDoesNotDrainQueue() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZacksBarStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = try AppSupportStore(directory: directory)
        let reload = commandMessage(id: "command-1", type: "extension.reload")
        let tabOpen = commandMessage(id: "command-2", type: "tab.open")

        try store.appendCommand(reload)
        try store.appendCommand(tabOpen)

        XCTAssertEqual(try store.readPendingCommands(), [reload, tabOpen])
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.commandsFile.path))
        XCTAssertEqual(try store.drainCommands(), [reload, tabOpen])
    }

    func testReadPendingCommandsSkipsMalformedLines() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZacksBarStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = try AppSupportStore(directory: directory)
        let valid = commandMessage(id: "command-1", type: "extension.reload")
        var contents = Data("not-json\n".utf8)
        contents.append(try JSONEncoder.zacksBar.encode(valid))
        contents.append(Data("\n".utf8))
        try contents.write(to: store.commandsFile)

        XCTAssertEqual(try store.readPendingCommands(), [valid])
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.commandsFile.path))
    }

    private func commandMessage(id: String, type: String) -> NativeMessage {
        NativeMessage(
            schemaVersion: 1,
            messageId: id,
            type: type,
            sentAt: Date(timeIntervalSince1970: 1_787_680_800),
            source: "zacksbar-app",
            payload: [:]
        )
    }
}
