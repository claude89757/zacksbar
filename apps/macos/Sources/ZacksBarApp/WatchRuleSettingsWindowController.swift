import AppKit
import ZacksBarCore

@MainActor
final class WatchRuleSettingsWindowController: NSWindowController {
    private let model: AppModel
    private let onSave: () -> Void
    private let startField = NSTextField()
    private let endField = NSTextField()
    private let keywordsField = NSTextField()
    private let summaryLabel = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(labelWithString: "")

    init(model: AppModel, onSave: @escaping () -> Void) {
        self.model = model
        self.onSave = onSave
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 330),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ZacksBar Alert Settings"
        window.isReleasedWhenClosed = false
        super.init(window: window)
        buildContent(in: window)
        refresh()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func refresh() {
        let rule = model.primaryWatchRule
        startField.stringValue = rule.start
        endField.stringValue = rule.end
        keywordsField.stringValue = rule.courtKeywords.joined(separator: ", ")
        renderSummary(rule)
        statusLabel.stringValue = "Changes apply immediately after Save"
    }

    private func buildContent(in window: NSWindow) {
        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = content

        let titleLabel = NSTextField(labelWithString: "Availability alert")
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        summaryLabel.font = .systemFont(ofSize: 12)
        summaryLabel.textColor = .secondaryLabelColor
        summaryLabel.lineBreakMode = .byTruncatingTail

        configureTextField(startField, placeholder: "19:00")
        configureTextField(endField, placeholder: "21:00")
        configureTextField(keywordsField, placeholder: "1号, 室内")

        let form = NSGridView(views: [
            [label("Start"), startField],
            [label("End"), endField],
            [label("Court keywords"), keywordsField]
        ])
        form.rowSpacing = 10
        form.columnSpacing = 12
        form.column(at: 0).xPlacement = .trailing
        form.column(at: 1).xPlacement = .fill

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor

        let saveButton = NSButton(title: "Save", target: self, action: #selector(save(_:)))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        let resetButton = NSButton(title: "Reset Default", target: self, action: #selector(resetDefault(_:)))
        resetButton.bezelStyle = .rounded
        let useCurrentPageButton = NSButton(title: "Use Current Page", target: self, action: #selector(useCurrentPage(_:)))
        useCurrentPageButton.bezelStyle = .rounded
        let refreshButton = NSButton(title: "Refresh", target: self, action: #selector(refreshButtonClicked(_:)))
        refreshButton.bezelStyle = .rounded
        let buttonRow = NSStackView(views: [saveButton, useCurrentPageButton, resetButton, refreshButton])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 8
        buttonRow.alignment = .centerY

        for view in [titleLabel, summaryLabel, form, statusLabel, buttonRow] {
            view.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(view)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            summaryLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            summaryLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            summaryLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            form.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 20),
            form.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            form.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            statusLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            statusLabel.bottomAnchor.constraint(equalTo: buttonRow.topAnchor, constant: -14),

            buttonRow.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            buttonRow.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -20),
            buttonRow.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20)
        ])
    }

    private func configureTextField(_ field: NSTextField, placeholder: String) {
        field.placeholderString = placeholder
        field.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
    }

    private func label(_ title: String) -> NSTextField {
        let field = NSTextField(labelWithString: title)
        field.font = .systemFont(ofSize: 12, weight: .semibold)
        field.textColor = .secondaryLabelColor
        return field
    }

    private func makeRuleFromFields() throws -> WatchRule {
        let start = startField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let end = endField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !start.isEmpty, !end.isEmpty else {
            throw WatchRuleSettingsError.emptyTime
        }
        return WatchRule(
            id: model.primaryWatchRule.id,
            dateMode: .latestBookable,
            start: start,
            end: end,
            courtKeywords: keywordsField.normalizedKeywords
        )
    }

    private func renderSummary(_ rule: WatchRule) {
        let courts = rule.courtKeywords.isEmpty ? "any court" : rule.courtKeywords.joined(separator: ", ")
        summaryLabel.stringValue = "\(rule.start)-\(rule.end), \(courts)"
    }

    @objc private func save(_ sender: Any?) {
        do {
            let rule = try makeRuleFromFields()
            try model.savePrimaryWatchRule(rule)
            renderSummary(rule)
            statusLabel.stringValue = "Saved"
            onSave()
        } catch {
            statusLabel.stringValue = "Save failed: \(error.localizedDescription)"
        }
    }

    @objc private func resetDefault(_ sender: Any?) {
        guard let rule = WatchRule.defaultRules.first else { return }
        do {
            try model.savePrimaryWatchRule(rule)
            refresh()
            statusLabel.stringValue = "Restored default"
            onSave()
        } catch {
            statusLabel.stringValue = "Reset failed: \(error.localizedDescription)"
        }
    }

    @objc private func useCurrentPage(_ sender: Any?) {
        guard let suggestion = model.makeWatchRuleSuggestion() else {
            statusLabel.stringValue = "No available range in latest page state"
            return
        }

        startField.stringValue = suggestion.start
        endField.stringValue = suggestion.end
        renderSummary(WatchRule(
            id: model.primaryWatchRule.id,
            dateMode: .latestBookable,
            start: suggestion.start,
            end: suggestion.end,
            courtKeywords: keywordsField.normalizedKeywords
        ))
        statusLabel.stringValue = "Filled \(suggestion.start)-\(suggestion.end) from latest page"
    }

    @objc private func refreshButtonClicked(_ sender: Any?) {
        refresh()
    }
}

private enum WatchRuleSettingsError: LocalizedError {
    case emptyTime

    var errorDescription: String? {
        switch self {
        case .emptyTime:
            return "Start and end are required."
        }
    }
}

private extension NSTextField {
    var normalizedKeywords: [String] {
        stringValue
            .replacingOccurrences(of: "，", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
