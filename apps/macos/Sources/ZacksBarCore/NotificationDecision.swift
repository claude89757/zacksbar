import Foundation

public struct PendingNotification: Equatable {
    public var id: String
    public var title: String
    public var body: String
    public var actionURL: String?

    public init(id: String, title: String, body: String, actionURL: String? = nil) {
        self.id = id
        self.title = title
        self.body = body
        self.actionURL = actionURL
    }
}

public enum NotificationDecision {
    public static func pendingNotifications(
        for state: LatestAppState,
        rules: [WatchRule],
        deliveredNotificationIDs: Set<String>
    ) -> [PendingNotification] {
        var notifications: [PendingNotification] = []

        if state.latestMessageType == "captcha.detected",
           let captcha = state.latestCaptcha {
            let notification = PendingNotification(
                id: "captcha:\(captcha.messageId)",
                title: "ZacksBar needs captcha",
                body: "Open Chrome to finish verification.",
                actionURL: captcha.payload["pageUrl"]?.nonEmptyStringValue
            )
            if !deliveredNotificationIDs.contains(notification.id) {
                notifications.append(notification)
            }
        }

        if let availability = state.latestAvailability {
            let slots = availability.availabilitySlots
            for rule in rules {
                guard let match = rule.match(slots: slots),
                      let first = match.slots.first,
                      let last = match.slots.last else {
                    continue
                }
                let id = "availability:\(availability.messageId):\(rule.id):\(match.courtName):\(first.start)-\(last.end)"
                guard !deliveredNotificationIDs.contains(id) else { continue }
                notifications.append(PendingNotification(
                    id: id,
                    title: "Court available",
                    body: availability.availabilityBody(
                        courtName: match.courtName,
                        start: first.start,
                        end: last.end
                    ),
                    actionURL: availability.payload["pageUrl"]?.nonEmptyStringValue
                ))
            }
        }

        return notifications
    }
}

private extension NativeMessage {
    func availabilityBody(courtName: String, start: String, end: String) -> String {
        [
            payload["venue"]?.nonEmptyStringValue,
            payload["dateLabel"]?.nonEmptyStringValue,
            courtName,
            "\(start)-\(end)"
        ].compactMap { $0 }.joined(separator: " ")
    }
}

private extension JSONValue {
    var nonEmptyStringValue: String? {
        guard let value = stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        return value
    }

}
