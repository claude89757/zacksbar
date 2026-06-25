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
        manifestURL: URL = DiagnosticPaths.defaultChromeNativeHostManifest
    ) throws -> SetupChecklist {
        let nativeHostReady = FileManager.default.fileExists(atPath: nativeHostExecutable.path)
        let manifestReady = FileManager.default.fileExists(atPath: manifestURL.path)
        let latestState = try readLatestState()
        let latestMessage = latestState?.latestMessageType
        let parserDiagnostics = latestState?.latestParserDiagnostics
        let parserSlotCount = parserDiagnostics?.payload["slotCount"]?.intValue

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
                label: "Parser Diagnostics",
                value: parserSlotCount.map { "\($0) slots" } ?? "waiting",
                isComplete: parserDiagnostics != nil
            )
        ])
    }
}

private extension JSONValue {
    var intValue: Int? {
        if case .number(let value) = self { return Int(value) }
        return nil
    }
}
