import ZacksBarCore

@MainActor
protocol NotificationDelivering: AnyObject {
    func requestAuthorization()
    func deliver(_ notification: PendingNotification)
}

@MainActor
final class NoopNotificationDelivery: NotificationDelivering {
    func requestAuthorization() {}
    func deliver(_ notification: PendingNotification) {}
}
