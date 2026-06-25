import AppKit
import ZacksBarCore

@MainActor
final class SetupAssistantWindowController: NSWindowController {
    private let model: AppModel
    private let openDiagnostics: () -> Void
    private let extensionIDField = NSTextField()
    private let statusLabel = NSTextField(labelWithString: "")
    private let checklistStack = NSStackView()

    init(model: AppModel, openDiagnostics: @escaping () -> Void) {
        self.model = model
        self.openDiagnostics = openDiagnostics
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 390),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ZacksBar Setup Assistant"
        window.isReleasedWhenClosed = false
        super.init(window: window)
        buildContent(in: window)
        refresh()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func refresh() {
        let checklist = model.makeSetupChecklist(extensionID: extensionIDField.stringValue)
        render(checklist)
    }

    private func buildContent(in window: NSWindow) {
        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = content

        let titleLabel = NSTextField(labelWithString: "First-run setup")
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        let extensionIDLabel = NSTextField(labelWithString: "Chrome Extension ID")
        extensionIDLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        extensionIDField.placeholderString = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        extensionIDField.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        extensionIDField.target = self
        extensionIDField.action = #selector(refreshFromField(_:))

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor

        checklistStack.orientation = .vertical
        checklistStack.alignment = .leading
        checklistStack.spacing = 8

        let installButton = NSButton(title: "Install Native Host", target: self, action: #selector(installNativeHost(_:)))
        installButton.bezelStyle = .rounded
        let reloadExtensionButton = NSButton(title: "Reload Browser Extension", target: self, action: #selector(reloadBrowserExtension(_:)))
        reloadExtensionButton.bezelStyle = .rounded
        let refreshButton = NSButton(title: "Refresh", target: self, action: #selector(refreshButtonClicked(_:)))
        refreshButton.bezelStyle = .rounded
        let diagnosticsButton = NSButton(title: "Diagnostics", target: self, action: #selector(openDiagnosticsButtonClicked(_:)))
        diagnosticsButton.bezelStyle = .rounded

        let buttonRow = NSStackView(views: [installButton, reloadExtensionButton, refreshButton, diagnosticsButton])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 8
        buttonRow.alignment = .centerY

        for view in [titleLabel, extensionIDLabel, extensionIDField, checklistStack, statusLabel, buttonRow] {
            view.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(view)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            extensionIDLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            extensionIDLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            extensionIDLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            extensionIDField.topAnchor.constraint(equalTo: extensionIDLabel.bottomAnchor, constant: 6),
            extensionIDField.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            extensionIDField.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            checklistStack.topAnchor.constraint(equalTo: extensionIDField.bottomAnchor, constant: 20),
            checklistStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            checklistStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            statusLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            statusLabel.bottomAnchor.constraint(equalTo: buttonRow.topAnchor, constant: -14),

            buttonRow.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            buttonRow.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -20),
            buttonRow.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20)
        ])
    }

    private func render(_ checklist: SetupChecklist) {
        checklistStack.arrangedSubviews.forEach { view in
            checklistStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        for step in checklist.steps {
            checklistStack.addArrangedSubview(rowView(step))
        }
        statusLabel.stringValue = checklist.isReady ? "Setup is ready" : "Complete the missing items, then refresh"
    }

    private func rowView(_ step: SetupStep) -> NSView {
        let state = NSTextField(labelWithString: step.isComplete ? "Ready" : "Missing")
        state.font = .systemFont(ofSize: 12, weight: .semibold)
        state.textColor = step.isComplete ? .systemGreen : .systemRed
        state.widthAnchor.constraint(equalToConstant: 70).isActive = true

        let label = NSTextField(labelWithString: step.label)
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.widthAnchor.constraint(equalToConstant: 165).isActive = true

        let value = NSTextField(labelWithString: step.value)
        value.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        value.lineBreakMode = .byTruncatingMiddle
        value.maximumNumberOfLines = 1

        let row = NSStackView(views: [state, label, value])
        row.orientation = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 10
        return row
    }

    @objc private func refreshFromField(_ sender: Any?) {
        refresh()
    }

    @objc private func refreshButtonClicked(_ sender: Any?) {
        refresh()
    }

    @objc private func installNativeHost(_ sender: Any?) {
        do {
            let result = try model.installNativeHost(extensionID: extensionIDField.stringValue)
            statusLabel.stringValue = "Installed \(result.manifestURL.path)"
        } catch {
            statusLabel.stringValue = "Install failed: \(error)"
        }
        refresh()
    }

    @objc private func reloadBrowserExtension(_ sender: Any?) {
        do {
            try model.requestBrowserCompanionReload()
            refresh()
            statusLabel.stringValue = "Browser extension reload queued"
        } catch {
            refresh()
            statusLabel.stringValue = "Reload request failed: \(error)"
        }
    }

    @objc private func openDiagnosticsButtonClicked(_ sender: Any?) {
        openDiagnostics()
    }
}
