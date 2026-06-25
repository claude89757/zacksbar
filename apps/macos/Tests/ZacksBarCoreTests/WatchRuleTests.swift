import XCTest
@testable import ZacksBarCore

final class WatchRuleTests: XCTestCase {
    func testMatchesContinuousAvailableRangeOnPreferredCourt() {
        let rule = WatchRule(id: "rule-1", dateMode: .latestBookable, start: "19:00", end: "21:00", courtKeywords: ["1号"])
        let result = rule.match(slots: [
            AvailabilitySlot(courtId: "court-1", courtName: "1号场", start: "19:00", end: "20:00", available: true),
            AvailabilitySlot(courtId: "court-1", courtName: "1号场", start: "20:00", end: "21:00", available: true),
            AvailabilitySlot(courtId: "court-2", courtName: "2号场", start: "19:00", end: "20:00", available: true)
        ])

        XCTAssertEqual(result?.courtName, "1号场")
        XCTAssertEqual(result?.slots.count, 2)
    }
}
