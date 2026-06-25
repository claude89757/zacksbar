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

    init(store: AppSupportStore? = nil) {
        if let store {
            self.store = store
        } else {
            self.store = try? AppSupportStore()
        }
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
