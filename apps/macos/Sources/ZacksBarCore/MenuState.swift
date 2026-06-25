import Foundation

public struct MenuState: Equatable {
    public var statusText: String
    public var latestAlert: String?

    public init(statusText: String, latestAlert: String? = nil) {
        self.statusText = statusText
        self.latestAlert = latestAlert
    }
}

public extension LatestAppState {
    var menuState: MenuState {
        switch latestMessageType {
        case "captcha.detected":
            return MenuState(statusText: "Captcha required", latestAlert: "Open captcha page")
        case "availability.updated":
            guard let availability = latestAvailability else {
                return MenuState(statusText: "Monitoring")
            }
            let dateLabel = availability.payload["dateLabel"]?.stringValue ?? "latest"
            let venue = availability.payload["venue"]?.stringValue ?? "ydmap venue"
            let availableCount = availability.availableSlotCount
            let slotLabel = availableCount == 1 ? "slot" : "slots"
            return MenuState(
                statusText: "Monitoring \(dateLabel)",
                latestAlert: "\(venue) \(availableCount) available \(slotLabel)"
            )
        case "health.ping":
            return MenuState(statusText: "Connected")
        default:
            return MenuState(statusText: "Received \(latestMessageType)")
        }
    }
}

private extension NativeMessage {
    var availableSlotCount: Int {
        guard let slots = payload["slots"]?.arrayValue else { return 0 }
        return slots.filter { slot in
            guard case .object(let object) = slot else { return false }
            return object["available"]?.boolValue == true
        }.count
    }
}

private extension JSONValue {
    var arrayValue: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }
}
