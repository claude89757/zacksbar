import AppKit

@MainActor
final class MenuController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let model: AppModel
    private var diagnosticsWindowController: DiagnosticsWindowController?

    init(model: AppModel) {
        self.model = model
        super.init()
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
        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(refreshLatestState(_:)), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        menu.addItem(NSMenuItem(title: "Create watch rule from current page", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Pause monitoring for 30 minutes", action: nil, keyEquivalent: ""))
        let diagnosticsItem = NSMenuItem(title: "Settings and diagnostics...", action: #selector(openDiagnostics(_:)), keyEquivalent: ",")
        diagnosticsItem.target = self
        menu.addItem(diagnosticsItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func refreshLatestState(_ sender: Any?) {
        model.reloadLatestState()
        rebuildMenu()
    }

    @objc private func openDiagnostics(_ sender: Any?) {
        if diagnosticsWindowController == nil {
            diagnosticsWindowController = DiagnosticsWindowController(model: model)
        }
        diagnosticsWindowController?.refresh()
        diagnosticsWindowController?.showWindow(nil)
        diagnosticsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
