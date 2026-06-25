import Foundation
import ZacksBarCore

@MainActor
final class AppModel: ObservableObject {
    @Published var statusText: String = "Waiting for Chrome"
    @Published var latestAlert: String?
    @Published var rules: [WatchRule] = [
        WatchRule(id: "default-evening", dateMode: .latestBookable, start: "19:00", end: "21:00", courtKeywords: [])
    ]

    func handle(message: NativeMessage) {
        switch message.type {
        case "availability.updated":
            statusText = "Monitoring"
            latestAlert = "Availability synced"
        case "captcha.detected":
            statusText = "Captcha required"
            latestAlert = "Open captcha page"
        case "health.ping":
            statusText = "Connected"
        default:
            statusText = "Received \(message.type)"
        }
    }
}
