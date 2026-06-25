import Foundation
import ZacksBarCore

@MainActor
final class AppModel: ObservableObject {
    @Published var statusText: String = "Waiting for Chrome"
    @Published var latestAlert: String?
    @Published var rules: [WatchRule] = WatchRule.defaultRules

    private let store: AppSupportStore?
    private let nativeHostInstaller: NativeHostInstaller
    private let notificationDelivery: NotificationDelivering
    private var deliveredNotificationIDs: Set<String> = []

    init(
        store: AppSupportStore? = nil,
        nativeHostInstaller: NativeHostInstaller = NativeHostInstaller(),
        notificationDelivery: NotificationDelivering? = nil
    ) {
        if let store {
            self.store = store
        } else {
            self.store = try? AppSupportStore()
        }
        self.nativeHostInstaller = nativeHostInstaller
        self.notificationDelivery = notificationDelivery ?? NoopNotificationDelivery()
        self.rules = (try? self.store?.readWatchRules()) ?? WatchRule.defaultRules
        reloadLatestState()
    }

    func reloadLatestState() {
        guard let state = try? store?.readLatestState() else {
            statusText = "Waiting for Chrome"
            latestAlert = nil
            return
        }
        apply(state.menuState)
        evaluateNotifications(for: state)
    }

    func makeDiagnosticReport() -> DiagnosticReport {
        if let report = try? store?.makeDiagnosticReport() {
            return report
        }
        return DiagnosticReport(
            summary: "Store unavailable",
            rows: [
                DiagnosticRow(label: "Application Support", value: "unavailable"),
                DiagnosticRow(label: "Latest State", value: "unavailable"),
                DiagnosticRow(label: "Native Events", value: "unavailable"),
                DiagnosticRow(label: "Native Host Manifest", value: "unknown"),
                DiagnosticRow(label: "Latest Message", value: "none")
            ]
        )
    }

    func makeSetupChecklist(extensionID rawExtensionID: String?) -> SetupChecklist {
        let extensionID = try? rawExtensionID.flatMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : try ChromeExtensionID(trimmed)
        }
        if let checklist = try? store?.makeSetupChecklist(
            extensionID: extensionID,
            nativeHostExecutable: nativeHostExecutableURL
        ) {
            return checklist
        }
        return SetupChecklist(steps: [
            SetupStep(label: "Chrome Extension ID", value: extensionID?.rawValue ?? "missing", isComplete: extensionID != nil),
            SetupStep(label: "Native Host Executable", value: "missing", isComplete: false),
            SetupStep(label: "Native Host Manifest", value: "missing", isComplete: false),
            SetupStep(label: "Latest Browser State", value: "waiting", isComplete: false)
        ])
    }

    func installNativeHost(extensionID rawExtensionID: String) throws -> NativeHostInstallResult {
        let extensionID = try ChromeExtensionID(rawExtensionID.trimmingCharacters(in: .whitespacesAndNewlines))
        return try nativeHostInstaller.install(
            nativeHostExecutable: nativeHostExecutableURL,
            extensionID: extensionID
        )
    }

    func savePrimaryWatchRule(_ rule: WatchRule) throws {
        let nextRules = [rule.timeRangeOnly]
        try store?.writeWatchRules(nextRules)
        rules = nextRules
        reloadLatestState()
    }

    func makeWatchRuleSuggestion() -> WatchRuleSuggestion? {
        guard let state = try? store?.readLatestState() else {
            return nil
        }
        return WatchRuleSuggestionBuilder.firstContinuousAvailableRange(from: state.latestAvailability)
    }

    func requestBrowserCompanionReload() throws {
        let command = NativeMessage(
            schemaVersion: 1,
            messageId: "command-\(UUID().uuidString)",
            type: "extension.reload",
            sentAt: Date(),
            source: "zacksbar-app",
            payload: [:]
        )
        try store?.appendCommand(command)
    }

    var primaryWatchRule: WatchRule {
        rules.first ?? WatchRule.defaultRules[0]
    }

    var nativeHostExecutableURL: URL {
        let executableDirectory = Bundle.main.executableURL?.deletingLastPathComponent()
            ?? URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
        return executableDirectory.appendingPathComponent("zacksbar-native-host")
    }

    func handle(message: NativeMessage) {
        let state = LatestAppState(
            updatedAt: message.sentAt,
            latestAvailability: message.type == "availability.updated" ? message : nil,
            latestCaptcha: message.type == "captcha.detected" ? message : nil,
            latestHealth: message.type == "health.ping" ? message : nil,
            latestParserDiagnostics: message.type == "parser.diagnostics" ? message : nil,
            latestMessageType: message.type
        )
        apply(state.menuState)
        evaluateNotifications(for: state)
    }

    private func apply(_ menuState: MenuState) {
        statusText = menuState.statusText
        latestAlert = menuState.latestAlert
    }

    private func evaluateNotifications(for state: LatestAppState) {
        let pending = NotificationDecision.pendingNotifications(
            for: state,
            rules: rules,
            deliveredNotificationIDs: deliveredNotificationIDs
        )
        for notification in pending {
            notificationDelivery.deliver(notification)
            deliveredNotificationIDs.insert(notification.id)
        }
    }

}

private extension WatchRule {
    var timeRangeOnly: WatchRule {
        WatchRule(
            id: id,
            dateMode: .latestBookable,
            start: start,
            end: end,
            courtKeywords: courtKeywords
        )
    }
}
