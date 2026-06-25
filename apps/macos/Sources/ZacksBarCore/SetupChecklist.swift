import Foundation

public struct SetupStep: Equatable {
    public var label: String
    public var value: String
    public var isComplete: Bool

    public init(label: String, value: String, isComplete: Bool) {
        self.label = label
        self.value = value
        self.isComplete = isComplete
    }
}

public struct SetupChecklist: Equatable {
    public var steps: [SetupStep]

    public init(steps: [SetupStep]) {
        self.steps = steps
    }

    public var isReady: Bool {
        steps.allSatisfy(\.isComplete)
    }

    public func value(for label: String) -> String? {
        steps.first { $0.label == label }?.value
    }
}

public extension AppSupportStore {
    func makeSetupChecklist(
        extensionID: ChromeExtensionID?,
        nativeHostExecutable: URL,
        manifestURL: URL = DiagnosticPaths.defaultChromeNativeHostManifest,
        expectedCompanionVersion: String = "0.1.0"
    ) throws -> SetupChecklist {
        let nativeHostReady = FileManager.default.fileExists(atPath: nativeHostExecutable.path)
        let manifestReady = FileManager.default.fileExists(atPath: manifestURL.path)
        let latestState = try readLatestState()
        let latestMessage = latestState?.latestMessageType
        let companionVersion = latestState?.latestHealth?.payload["version"]?.stringValue
        let parserDiagnostics = latestState?.latestParserDiagnostics
        let parserSlotCount = parserDiagnostics?.payload["slotCount"]?.intValue
        let pendingCommands = try readPendingCommands()
        let companionStatus = companionStatus(
            actualVersion: companionVersion,
            expectedVersion: expectedCompanionVersion
        )
        let pendingCommandStatus = pendingCommandStatus(pendingCommands)

        return SetupChecklist(steps: [
            SetupStep(
                label: "Chrome Extension ID",
                value: extensionID?.rawValue ?? "missing",
                isComplete: extensionID != nil
            ),
            SetupStep(
                label: "Native Host Executable",
                value: nativeHostReady ? "ready" : "missing",
                isComplete: nativeHostReady
            ),
            SetupStep(
                label: "Native Host Manifest",
                value: manifestReady ? "installed" : "missing",
                isComplete: manifestReady
            ),
            SetupStep(
                label: "Latest Browser State",
                value: latestMessage ?? "waiting",
                isComplete: latestMessage != nil
            ),
            SetupStep(
                label: "Browser Companion",
                value: companionStatus.value,
                isComplete: companionStatus.isComplete
            ),
            SetupStep(
                label: "Pending Browser Commands",
                value: pendingCommandStatus.value,
                isComplete: pendingCommandStatus.isComplete
            ),
            SetupStep(
                label: "Parser Diagnostics",
                value: parserSlotCount.map { "\($0) slots" } ?? "waiting",
                isComplete: parserDiagnostics != nil
            )
        ])
    }

    private func companionStatus(actualVersion: String?, expectedVersion: String) -> (value: String, isComplete: Bool) {
        guard let actualVersion else {
            return ("waiting", false)
        }
        guard actualVersion == expectedVersion else {
            return ("reload \(actualVersion) -> \(expectedVersion)", false)
        }
        return (actualVersion, true)
    }

    private func pendingCommandStatus(_ commands: [NativeMessage]) -> (value: String, isComplete: Bool) {
        guard !commands.isEmpty else {
            return ("0 pending", true)
        }
        let visibleTypes = commands.prefix(3).map(\.type).joined(separator: ", ")
        let suffix = commands.count > 3 ? ", ..." : ""
        return ("\(commands.count) pending: \(visibleTypes)\(suffix)", false)
    }
}

private extension JSONValue {
    var intValue: Int? {
        if case .number(let value) = self { return Int(value) }
        return nil
    }
}
