import Foundation
import ZacksBarCore

@MainActor
final class AppModel: ObservableObject {
    @Published var statusText: String = "Waiting for Chrome"
    @Published var latestAlert: String?
    @Published var rules: [WatchRule] = [
        WatchRule(id: "default-evening", dateMode: .latestBookable, start: "19:00", end: "21:00", courtKeywords: [])
    ]

    private let store: AppSupportStore?
    private let nativeHostInstaller: NativeHostInstaller

    init(store: AppSupportStore? = nil, nativeHostInstaller: NativeHostInstaller = NativeHostInstaller()) {
        if let store {
            self.store = store
        } else {
            self.store = try? AppSupportStore()
        }
        self.nativeHostInstaller = nativeHostInstaller
        reloadLatestState()
    }

    func reloadLatestState() {
        guard let state = try? store?.readLatestState() else {
            statusText = "Waiting for Chrome"
            latestAlert = nil
            return
        }
        apply(state.menuState)
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
            latestMessageType: message.type
        )
        apply(state.menuState)
    }

    private func apply(_ menuState: MenuState) {
        statusText = menuState.statusText
        latestAlert = menuState.latestAlert
    }

}
