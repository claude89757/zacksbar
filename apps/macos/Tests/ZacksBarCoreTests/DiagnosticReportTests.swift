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
}
