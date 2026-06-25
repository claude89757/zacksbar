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
}
