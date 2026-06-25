import Foundation

public enum DateMode: String, Codable, Equatable {
    case tomorrow
    case latestBookable
    case weekend
    case specific
}

public struct AvailabilitySlot: Codable, Equatable {
    public var courtId: String
    public var courtName: String
    public var start: String
    public var end: String
    public var available: Bool

    public init(courtId: String, courtName: String, start: String, end: String, available: Bool) {
        self.courtId = courtId
        self.courtName = courtName
        self.start = start
        self.end = end
        self.available = available
    }
}

public struct RuleMatch: Equatable {
    public var ruleId: String
    public var courtName: String
    public var slots: [AvailabilitySlot]
}

public struct WatchRule: Codable, Equatable, Identifiable {
    public var id: String
    public var dateMode: DateMode
    public var start: String
    public var end: String
    public var courtKeywords: [String]

    public init(id: String, dateMode: DateMode, start: String, end: String, courtKeywords: [String]) {
        self.id = id
        self.dateMode = dateMode
        self.start = start
        self.end = end
        self.courtKeywords = courtKeywords
    }

    public func match(slots: [AvailabilitySlot]) -> RuleMatch? {
        let availableSlots = slots.filter { slot in
            slot.available && (courtKeywords.isEmpty || courtKeywords.contains { slot.courtName.contains($0) })
        }
        let groups = Dictionary(grouping: availableSlots, by: \.courtId)

        for group in groups.values {
            let sorted = group.sorted { $0.start < $1.start }
            var selected: [AvailabilitySlot] = []
            var cursor = start
            for slot in sorted {
                if slot.start == cursor {
                    selected.append(slot)
                    cursor = slot.end
                }
                if cursor == end, let courtName = selected.first?.courtName {
                    return RuleMatch(ruleId: id, courtName: courtName, slots: selected)
                }
            }
        }

        return nil
    }
}
