import XCTest
@testable import ZacksBarCore

final class WatchRuleSuggestionTests: XCTestCase {
    func testSuggestsFirstContinuousAvailableRangeFromAvailabilityMessage() {
        let suggestion = WatchRuleSuggestionBuilder.firstContinuousAvailableRange(from: availabilityMessage())

        XCTAssertEqual(suggestion, WatchRuleSuggestion(
            start: "18:00",
            end: "20:00",
            courtName: "2号场"
        ))
    }

    func testReturnsNilWhenNoAvailableSlotsExist() {
        let suggestion = WatchRuleSuggestionBuilder.firstContinuousAvailableRange(from: availabilityMessage(available: false))

        XCTAssertNil(suggestion)
    }

    func testReturnsNilWhenMessageIsMissing() {
        let suggestion = WatchRuleSuggestionBuilder.firstContinuousAvailableRange(from: nil)

        XCTAssertNil(suggestion)
    }

    private func availabilityMessage(available: Bool = true) -> NativeMessage {
        NativeMessage(
            schemaVersion: 1,
            messageId: "availability-1",
            type: "availability.updated",
            sentAt: Date(timeIntervalSince1970: 1_787_680_800),
            source: "content-script",
            payload: [
                "courts": .array([
                    .object(["id": .string("court-1"), "name": .string("1号场")]),
                    .object(["id": .string("court-2"), "name": .string("2号场")])
                ]),
                "slots": .array([
                    .object([
                        "courtId": .string("court-1"),
                        "start": .string("20:00"),
                        "end": .string("21:00"),
                        "available": .bool(available)
                    ]),
                    .object([
                        "courtId": .string("court-2"),
                        "start": .string("18:00"),
                        "end": .string("19:00"),
                        "available": .bool(available)
                    ]),
                    .object([
                        "courtId": .string("court-2"),
                        "start": .string("19:00"),
                        "end": .string("20:00"),
                        "available": .bool(available)
                    ])
                ])
            ]
        )
    }
}
