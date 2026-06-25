import Foundation

public struct WatchRuleSuggestion: Equatable {
    public var start: String
    public var end: String
    public var courtName: String

    public init(start: String, end: String, courtName: String) {
        self.start = start
        self.end = end
        self.courtName = courtName
    }
}

public enum WatchRuleSuggestionBuilder {
    public static func firstContinuousAvailableRange(from message: NativeMessage?) -> WatchRuleSuggestion? {
        guard let message, message.type == "availability.updated" else {
            return nil
        }
        return firstContinuousAvailableRange(from: message.availabilitySlots)
    }

    public static func firstContinuousAvailableRange(from slots: [AvailabilitySlot]) -> WatchRuleSuggestion? {
        let availableSlots = slots.filter(\.available)
        guard !availableSlots.isEmpty else { return nil }

        let slotsByCourt = Dictionary(grouping: availableSlots, by: \.courtId)
            .mapValues { $0.sorted(by: precedes) }

        for seed in availableSlots.sorted(by: precedes) {
            guard let courtSlots = slotsByCourt[seed.courtId] else { continue }
            var end = seed.end

            while let next = courtSlots.first(where: { $0.start == end && $0.end != end }) {
                end = next.end
            }

            return WatchRuleSuggestion(start: seed.start, end: end, courtName: seed.courtName)
        }

        return nil
    }

    private static func precedes(_ lhs: AvailabilitySlot, _ rhs: AvailabilitySlot) -> Bool {
        if lhs.start != rhs.start { return lhs.start < rhs.start }
        if lhs.courtName != rhs.courtName { return lhs.courtName < rhs.courtName }
        if lhs.courtId != rhs.courtId { return lhs.courtId < rhs.courtId }
        return lhs.end < rhs.end
    }
}

public extension NativeMessage {
    var availabilitySlots: [AvailabilitySlot] {
        let courtNames = payload["courts"]?.objectArrayValue?.reduce(into: [String: String]()) { result, object in
            guard let id = object["id"]?.stringValue,
                  let name = object["name"]?.stringValue else {
                return
            }
            result[id] = name
        } ?? [:]

        return payload["slots"]?.objectArrayValue?.compactMap { object in
            guard let courtId = object["courtId"]?.stringValue,
                  let start = object["start"]?.stringValue,
                  let end = object["end"]?.stringValue,
                  let available = object["available"]?.boolValue else {
                return nil
            }
            return AvailabilitySlot(
                courtId: courtId,
                courtName: object["courtName"]?.stringValue ?? courtNames[courtId] ?? courtId,
                start: start,
                end: end,
                available: available
            )
        } ?? []
    }
}

private extension JSONValue {
    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    var objectArrayValue: [[String: JSONValue]]? {
        guard case .array(let values) = self else { return nil }
        return values.compactMap { value in
            guard case .object(let object) = value else { return nil }
            return object
        }
    }
}
