import AppKit
import ZacksBarCore

@MainActor
final class DiagnosticsWindowController: NSWindowController {
    private let model: AppModel
    private let summaryLabel = NSTextField(labelWithString: "")
    private let stackView = NSStackView()
    private var report: DiagnosticReport?

    init(model: AppModel) {
        self.model = model
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ZacksBar Diagnostics"
        window.isReleasedWhenClosed = false
        super.init(window: window)
        buildContent(in: window)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func refresh() {
        report = model.makeDiagnosticReport()
        render(report)
    }

    private func buildContent(in window: NSWindow) {
        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = content

        summaryLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        summaryLabel.lineBreakMode = .byTruncatingTail

        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.documentView = stackView
        scrollView.borderType = .bezelBorder

        let refreshButton = NSButton(title: "Refresh", target: self, action: #selector(refreshButtonClicked(_:)))
        refreshButton.bezelStyle = .rounded

        let copyButton = NSButton(title: "Copy Report", target: self, action: #selector(copyReport(_:)))
        copyButton.bezelStyle = .rounded

        let buttonRow = NSStackView(views: [refreshButton, copyButton])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 8
        buttonRow.alignment = .centerY

        for view in [summaryLabel, scrollView, buttonRow] {
            view.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(view)
        }

        NSLayoutConstraint.activate([
            summaryLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            summaryLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            summaryLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            scrollView.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: buttonRow.topAnchor, constant: -16),

            stackView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor, constant: -12),
            stackView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor, constant: 12),

            buttonRow.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            buttonRow.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -20),
            buttonRow.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20)
        ])
    }

    private func render(_ report: DiagnosticReport?) {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        guard let report else {
            summaryLabel.stringValue = "Diagnostics unavailable"
            return
        }

        summaryLabel.stringValue = report.summary
        for row in report.rows {
            stackView.addArrangedSubview(rowView(label: row.label, value: row.value))
        }
    }

    private func rowView(label: String, value: String) -> NSView {
        let labelField = NSTextField(labelWithString: label)
        labelField.font = .systemFont(ofSize: 12, weight: .semibold)
        labelField.textColor = .secondaryLabelColor
        labelField.setContentCompressionResistancePriority(.required, for: .horizontal)
        labelField.widthAnchor.constraint(equalToConstant: 150).isActive = true

        let valueField = NSTextField(labelWithString: value)
        valueField.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        valueField.lineBreakMode = .byTruncatingMiddle
        valueField.maximumNumberOfLines = 2

        let row = NSStackView(views: [labelField, valueField])
        row.orientation = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 12
        return row
    }

    @objc private func refreshButtonClicked(_ sender: Any?) {
        refresh()
    }

    @objc private func copyReport(_ sender: Any?) {
        guard let report else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report.plainText, forType: .string)
    }
}
