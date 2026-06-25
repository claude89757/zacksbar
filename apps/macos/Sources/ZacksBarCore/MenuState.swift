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
        if latestMessageType == "health.ping", latestAvailability == nil, latestCaptcha == nil, latestParserDiagnostics != nil {
            return parserMenuState
        }

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
        case "parser.diagnostics":
            return parserMenuState
        default:
            return MenuState(statusText: "Received \(latestMessageType)")
        }
    }

    private var parserMenuState: MenuState {
        guard let parser = latestParserDiagnostics else {
            return MenuState(statusText: "Inspecting page")
        }
        if parser.payload["scheduleTableFound"]?.boolValue == false {
            return MenuState(statusText: "Inspecting page", latestAlert: "Parser table missing")
        }
        let slotCount = parser.payload["slotCount"]?.intValue ?? 0
        return MenuState(statusText: "Inspecting page", latestAlert: "Parser found \(slotCount) slots")
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

    var intValue: Int? {
        if case .number(let value) = self { return Int(value) }
        return nil
    }
}
