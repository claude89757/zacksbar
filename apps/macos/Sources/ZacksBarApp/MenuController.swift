import AppKit

@MainActor
final class MenuController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let model: AppModel

    init(model: AppModel) {
        self.model = model
        statusItem.button?.title = "ZB"
        rebuildMenu()
    }

    func rebuildMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "ZacksBar", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Status: \(model.statusText)", action: nil, keyEquivalent: ""))
        if let latestAlert = model.latestAlert {
            menu.addItem(NSMenuItem(title: "Alert: \(latestAlert)", action: nil, keyEquivalent: ""))
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Create watch rule from current page", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Pause monitoring for 30 minutes", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings and diagnostics...", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
}
