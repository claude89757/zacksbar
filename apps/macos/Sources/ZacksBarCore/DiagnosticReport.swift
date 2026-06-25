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
        if let alert = menuState.latestAlert {
            rows.append(DiagnosticRow(label: "Menu Alert", value: alert))
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
