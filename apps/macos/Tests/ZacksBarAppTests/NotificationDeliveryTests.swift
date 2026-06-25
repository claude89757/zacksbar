import XCTest
@testable import ZacksBarApp

@MainActor
final class NotificationDeliveryTests: XCTestCase {
    func testNotificationResponseRouterOpensActionURL() {
        let opener = RecordingBrowserOpener()
        let router = NotificationResponseRouter(browserOpener: opener)

        let handled = router.openActionURL(from: [
            "actionURL": "https://bawtt.ydmap.cn/booking/schedule/example"
        ])

        XCTAssertTrue(handled)
        XCTAssertEqual(opener.openedURLs, [
            URL(string: "https://bawtt.ydmap.cn/booking/schedule/example")
        ])
    }

    func testNotificationResponseRouterIgnoresMissingActionURL() {
        let opener = RecordingBrowserOpener()
        let router = NotificationResponseRouter(browserOpener: opener)

        let handled = router.openActionURL(from: [:])

        XCTAssertFalse(handled)
        XCTAssertTrue(opener.openedURLs.isEmpty)
    }
}

@MainActor
private final class RecordingBrowserOpener: BrowserOpening {
    private(set) var openedURLs: [URL] = []

    func open(_ url: URL) {
        openedURLs.append(url)
    }
}
