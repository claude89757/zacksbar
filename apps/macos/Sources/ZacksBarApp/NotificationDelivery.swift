import AppKit
import UserNotifications
import ZacksBarCore

@MainActor
protocol NotificationDelivering: AnyObject {
    func requestAuthorization()
    func deliver(_ notification: PendingNotification)
}

@MainActor
protocol BrowserOpening: AnyObject {
    func open(_ url: URL)
}

@MainActor
final class NoopNotificationDelivery: NotificationDelivering {
    func requestAuthorization() {}
    func deliver(_ notification: PendingNotification) {}
}

@MainActor
final class ChromeBrowserOpener: BrowserOpening {
    func open(_ url: URL) {
        if let chromeURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.Chrome") {
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open([url], withApplicationAt: chromeURL, configuration: configuration) { _, _ in }
            return
        }
        NSWorkspace.shared.open(url)
    }
}

@MainActor
final class NotificationResponseRouter: NSObject, UNUserNotificationCenterDelegate {
    private let browserOpener: BrowserOpening

    init(browserOpener: BrowserOpening) {
        self.browserOpener = browserOpener
        super.init()
    }

    func openActionURL(from userInfo: [AnyHashable: Any]) -> Bool {
        guard let rawURL = userInfo["actionURL"] as? String,
              let url = URL(string: rawURL) else {
            return false
        }
        browserOpener.open(url)
        return true
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            _ = self.openActionURL(from: userInfo)
            completionHandler()
        }
    }
}

@MainActor
final class MacNotificationDelivery: NotificationDelivering {
    private let center: UNUserNotificationCenter
    private let responseRouter: NotificationResponseRouter

    init(
        center: UNUserNotificationCenter = .current(),
        browserOpener: BrowserOpening? = nil
    ) {
        self.center = center
        self.responseRouter = NotificationResponseRouter(browserOpener: browserOpener ?? ChromeBrowserOpener())
        self.center.delegate = responseRouter
    }

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func deliver(_ notification: PendingNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        if let actionURL = notification.actionURL {
            content.userInfo = ["actionURL": actionURL]
        }
        let request = UNNotificationRequest(identifier: notification.id, content: content, trigger: nil)
        center.add(request)
    }
}
