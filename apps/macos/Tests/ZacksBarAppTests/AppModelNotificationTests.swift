import XCTest
import ZacksBarCore
@testable import ZacksBarApp

@MainActor
final class AppModelNotificationTests: XCTestCase {
    func testReloadLatestStateDeliversMatchingAvailabilityNotification() throws {
        let store = try temporaryStore()
        let delivery = RecordingNotificationDelivery()
        try store.appendEvent(availabilityMessage())

        _ = AppModel(store: store, notificationDelivery: delivery)

        XCTAssertEqual(delivery.delivered, [
            PendingNotification(
                id: "availability:availability-1:default-evening:1号场:19:00-21:00",
                title: "Court available",
                body: "宝安网球馆 6-26 1号场 19:00-21:00",
                actionURL: "https://bawtt.ydmap.cn/booking/schedule/example"
            )
        ])
    }

    func testHandleMessageSuppressesDuplicateCaptchaNotification() throws {
        let store = try temporaryStore()
        let delivery = RecordingNotificationDelivery()
        let model = AppModel(store: store, notificationDelivery: delivery)
        let captcha = captchaMessage()

        model.handle(message: captcha)
        model.handle(message: captcha)

        XCTAssertEqual(delivery.delivered, [
            PendingNotification(
                id: "captcha:captcha-1",
                title: "ZacksBar needs captcha",
                body: "Open Chrome to finish verification.",
                actionURL: "https://bawtt.ydmap.cn/booking/schedule/example"
            )
        ])
    }

    private func temporaryStore() throws -> AppSupportStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZacksBarAppTests-\(UUID().uuidString)", isDirectory: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return try AppSupportStore(directory: directory)
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
                    .object(["id": .string("court-1"), "name": .string("1号场")])
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
                    ])
                ])
            ]
        )
    }

    private func captchaMessage() -> NativeMessage {
        NativeMessage(
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
    }
}

@MainActor
private final class RecordingNotificationDelivery: NotificationDelivering {
    private(set) var delivered: [PendingNotification] = []

    func requestAuthorization() {}

    func deliver(_ notification: PendingNotification) {
        delivered.append(notification)
    }
}
