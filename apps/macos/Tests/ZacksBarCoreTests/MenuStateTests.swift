import XCTest
@testable import ZacksBarCore

final class MenuStateTests: XCTestCase {
    func testMenuStateSummarizesAvailability() {
        let availability = NativeMessage(
            schemaVersion: 1,
            messageId: "availability-1",
            type: "availability.updated",
            sentAt: Date(timeIntervalSince1970: 1_787_680_800),
            source: "content-script",
            payload: [
                "venue": .string("宝安网球馆"),
                "dateLabel": .string("6-26"),
                "slots": .array([
                    .object(["available": .bool(true)]),
                    .object(["available": .bool(false)])
                ])
            ]
        )
        let state = LatestAppState(
            updatedAt: availability.sentAt,
            latestAvailability: availability,
            latestMessageType: "availability.updated"
        )

        let menuState = state.menuState

        XCTAssertEqual(menuState.statusText, "Monitoring 6-26")
        XCTAssertEqual(menuState.latestAlert, "宝安网球馆 1 available slot")
    }

    func testMenuStateSummarizesCaptcha() {
        let captcha = NativeMessage(
            schemaVersion: 1,
            messageId: "captcha-1",
            type: "captcha.detected",
            sentAt: Date(timeIntervalSince1970: 1_787_680_800),
            source: "content-script",
            payload: [
                "pageUrl": .string("https://bawtt.ydmap.cn/booking/schedule/example"),
                "reason": .string("captcha-text-match")
            ]
        )
        let state = LatestAppState(
            updatedAt: captcha.sentAt,
            latestCaptcha: captcha,
            latestMessageType: "captcha.detected"
        )

        let menuState = state.menuState

        XCTAssertEqual(menuState.statusText, "Captcha required")
        XCTAssertEqual(menuState.latestAlert, "Open captcha page")
    }
}
