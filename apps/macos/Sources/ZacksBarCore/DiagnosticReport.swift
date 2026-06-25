import Foundation

public struct DiagnosticRow: Equatable {
    public var label: String
    public var value: String

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

public struct DiagnosticReport: Equatable {
    public var generatedAt: Date
    public var summary: String
    public var rows: [DiagnosticRow]

    public init(generatedAt: Date = Date(), summary: String, rows: [DiagnosticRow]) {
        self.generatedAt = generatedAt
        self.summary = summary
        self.rows = rows
    }

    public func value(for label: String) -> String? {
        rows.first { $0.label == label }?.value
    }

    public var plainText: String {
        let body = rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n")
        return """
        ZacksBar Diagnostics
        Summary: \(summary)
        Generated At: \(ISO8601DateFormatter().string(from: generatedAt))
        \(body)
        """
    }
}

public enum DiagnosticPaths {
    public static var defaultChromeNativeHostManifest: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Google/Chrome/NativeMessagingHosts", isDirectory: true)
            .appendingPathComponent("com.zacksbar.native.json")
    }
}

public extension AppSupportStore {
    func makeDiagnosticReport(
        nativeHostManifestPath: URL = DiagnosticPaths.defaultChromeNativeHostManifest,
        now: Date = Date()
    ) throws -> DiagnosticReport {
        let state = try readLatestState()
        let menuState = state?.menuState ?? MenuState(statusText: "Waiting for Chrome")
        var rows = [
            DiagnosticRow(label: "Application Support", value: directory.path),
            DiagnosticRow(label: "Latest State", value: fileStatus(latestStateFile)),
            DiagnosticRow(label: "Native Events", value: fileStatus(eventsFile)),
            DiagnosticRow(label: "Native Host Manifest", value: fileStatus(nativeHostManifestPath)),
            DiagnosticRow(label: "Latest Message", value: state?.latestMessageType ?? "none")
        ]
        let watchRules = (try? readWatchRules()) ?? WatchRule.defaultRules
        rows.append(DiagnosticRow(label: "Watch Rules", value: "\(watchRules.count) \(watchRules.count == 1 ? "rule" : "rules")"))
        if let primaryRule = watchRules.first {
            rows.append(DiagnosticRow(label: "Primary Watch Rule", value: primaryRule.diagnosticSummary))
        }
        if let alert = menuState.latestAlert {
            rows.append(DiagnosticRow(label: "Menu Alert", value: alert))
        }
        if let parser = state?.latestParserDiagnostics {
            rows.append(contentsOf: [
                DiagnosticRow(label: "Parser Vue Root", value: parser.payload["vueRootFound"]?.foundValue ?? "unknown"),
                DiagnosticRow(label: "Parser Table", value: parser.payload["scheduleTableFound"]?.foundValue ?? "unknown"),
                DiagnosticRow(label: "Parser Rows", value: parser.payload["rowCount"]?.displayValue ?? "unknown"),
                DiagnosticRow(label: "Parser Slots", value: parser.payload["slotCount"]?.displayValue ?? "unknown"),
                DiagnosticRow(label: "Parser Available Slots", value: parser.payload["availableSlotCount"]?.displayValue ?? "unknown")
            ])
        }

        return DiagnosticReport(
            generatedAt: now,
            summary: menuState.statusText,
            rows: rows
        )
    }

    private func fileStatus(_ file: URL) -> String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
              let size = attributes[.size] as? NSNumber else {
            return "missing"
        }
        return "\(size.intValue) bytes"
    }
}

private extension WatchRule {
    var diagnosticSummary: String {
        let courts = courtKeywords.isEmpty ? "any court" : courtKeywords.joined(separator: ", ")
        return "\(start)-\(end) \(courts)"
    }
}

private extension JSONValue {
    var foundValue: String? {
        guard case .bool(let value) = self else { return nil }
        return value ? "found" : "missing"
    }

    var displayValue: String? {
        switch self {
        case .number(let value):
            let intValue = Int(value)
            return value == Double(intValue) ? String(intValue) : String(value)
        case .string(let value):
            return value
        case .bool(let value):
            return value ? "true" : "false"
        default:
            return nil
        }
    }
}
