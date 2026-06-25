import XCTest
@testable import ZacksBarCore

final class DiagnosticReportTests: XCTestCase {
    func testEmptyStoreReportsMissingRuntimeStateAndManifest() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZacksBarDiagnosticsTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = try AppSupportStore(directory: directory)
        let manifestPath = directory.appendingPathComponent("com.zacksbar.native.json")

        let report = try store.makeDiagnosticReport(nativeHostManifestPath: manifestPath)

        XCTAssertEqual(report.summary, "Waiting for Chrome")
        XCTAssertEqual(report.value(for: "Application Support"), directory.path)
        XCTAssertEqual(report.value(for: "Latest State"), "missing")
        XCTAssertEqual(report.value(for: "Native Events"), "missing")
        XCTAssertEqual(report.value(for: "Native Host Manifest"), "missing")
        XCTAssertEqual(report.value(for: "Latest Message"), "none")
    }

    func testReportIncludesLatestStateSummaryAndPlainText() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZacksBarDiagnosticsTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = try AppSupportStore(directory: directory)
        let manifestPath = directory.appendingPathComponent("com.zacksbar.native.json")
        FileManager.default.createFile(atPath: manifestPath.path, contents: Data("{}".utf8))
        let message = NativeMessage(
            schemaVersion: 1,
            messageId: "availability-1",
            type: "availability.updated",
            sentAt: Date(timeIntervalSince1970: 1_787_680_800),
            source: "content-script",
            payload: [
                "venue": .string("宝安网球馆"),
                "dateLabel": .string("6-26"),
                "slots": .array([
                    .object(["available": .bool(true)]),
                    .object(["available": .bool(false)])
                ])
            ]
        )
        try store.appendEvent(message)

        let report = try store.makeDiagnosticReport(nativeHostManifestPath: manifestPath, now: message.sentAt)

        XCTAssertEqual(report.summary, "Monitoring 6-26")
        XCTAssertEqual(report.value(for: "Latest Message"), "availability.updated")
        XCTAssertEqual(report.value(for: "Menu Alert"), "宝安网球馆 1 available slot")
        XCTAssertEqual(report.value(for: "Native Host Manifest"), "2 bytes")
        XCTAssertTrue(report.plainText.contains("ZacksBar Diagnostics"))
        XCTAssertTrue(report.plainText.contains("Application Support: \(directory.path)"))
        XCTAssertTrue(report.plainText.contains("Latest Message: availability.updated"))
    }
}
