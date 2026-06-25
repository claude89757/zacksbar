import XCTest
@testable import ZacksBarCore

final class NotificationDecisionTests: XCTestCase {
    func testBuildsCaptchaNotificationWithActionURL() {
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

        let notifications = NotificationDecision.pendingNotifications(
            for: state,
            rules: [],
            deliveredNotificationIDs: []
        )

        XCTAssertEqual(notifications, [
            PendingNotification(
                id: "captcha:captcha-1",
                title: "ZacksBar needs captcha",
                body: "Open Chrome to finish verification.",
                actionURL: "https://bawtt.ydmap.cn/booking/schedule/example"
            )
        ])
    }

    func testBuildsAvailabilityNotificationForMatchingWatchRule() {
        let availability = availabilityMessage()
        let state = LatestAppState(
            updatedAt: availability.sentAt,
            latestAvailability: availability,
            latestMessageType: "availability.updated"
        )
        let rule = WatchRule(
            id: "default-evening",
            dateMode: .latestBookable,
            start: "19:00",
            end: "21:00",
            courtKeywords: ["1号"]
        )

        let notifications = NotificationDecision.pendingNotifications(
            for: state,
            rules: [rule],
            deliveredNotificationIDs: []
        )

        XCTAssertEqual(notifications, [
            PendingNotification(
                id: "availability:availability-1:default-evening:1号场:19:00-21:00",
                title: "Court available",
                body: "宝安网球馆 6-26 1号场 19:00-21:00",
                actionURL: "https://bawtt.ydmap.cn/booking/schedule/example"
            )
        ])
    }

    func testDoesNotNotifyWhenAvailabilityDoesNotMatchRule() {
        let availability = availabilityMessage()
        let state = LatestAppState(
            updatedAt: availability.sentAt,
            latestAvailability: availability,
            latestMessageType: "availability.updated"
        )
        let rule = WatchRule(
            id: "late-night",
            dateMode: .latestBookable,
            start: "21:00",
            end: "22:00",
            courtKeywords: []
        )

        let notifications = NotificationDecision.pendingNotifications(
            for: state,
            rules: [rule],
            deliveredNotificationIDs: []
        )

        XCTAssertTrue(notifications.isEmpty)
    }

    func testSuppressesAlreadyDeliveredNotifications() {
        let availability = availabilityMessage()
        let state = LatestAppState(
            updatedAt: availability.sentAt,
            latestAvailability: availability,
            latestMessageType: "availability.updated"
        )
        let rule = WatchRule(
            id: "default-evening",
            dateMode: .latestBookable,
            start: "19:00",
            end: "21:00",
            courtKeywords: []
        )

        let notifications = NotificationDecision.pendingNotifications(
            for: state,
            rules: [rule],
            deliveredNotificationIDs: [
                "availability:availability-1:default-evening:1号场:19:00-21:00"
            ]
        )

        XCTAssertTrue(notifications.isEmpty)
    }

    private func availabilityMessage() -> NativeMessage {
        NativeMessage(
            schemaVersion: 1,
            messageId: "availability-1",
            type: "availability.updated",
            sentAt: Date(timeIntervalSince1970: 1_787_680_800),
            source: "content-script",
            payload: [
                "venue": .string("宝安网球馆"),
                "pageUrl": .string("https://bawtt.ydmap.cn/booking/schedule/example"),
                "dateLabel": .string("6-26"),
                "courts": .array([
                    .object(["id": .string("court-1"), "name": .string("1号场")]),
                    .object(["id": .string("court-2"), "name": .string("2号场")])
                ]),
                "slots": .array([
                    .object([
                        "courtId": .string("court-1"),
                        "start": .string("19:00"),
                        "end": .string("20:00"),
                        "available": .bool(true)
                    ]),
                    .object([
                        "courtId": .string("court-1"),
                        "start": .string("20:00"),
                        "end": .string("21:00"),
                        "available": .bool(true)
                    ]),
                    .object([
                        "courtId": .string("court-2"),
                        "start": .string("19:00"),
                        "end": .string("20:00"),
                        "available": .bool(false)
                    ])
                ])
            ]
        )
    }
}
