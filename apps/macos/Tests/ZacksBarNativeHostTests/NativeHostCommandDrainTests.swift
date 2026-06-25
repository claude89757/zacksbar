import XCTest
import ZacksBarCore

final class NativeHostCommandDrainTests: XCTestCase {
    func testNativeHostDrainsQueuedCommandsBeforeAck() throws {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZacksBarNativeHostTests-\(UUID().uuidString)", isDirectory: true)
        let commandDirectory = tempRoot.appendingPathComponent("AppSupport", isDirectory: true)
        let fakeHome = tempRoot.appendingPathComponent("Home", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }
        try FileManager.default.createDirectory(at: fakeHome, withIntermediateDirectories: true)

        let store = try AppSupportStore(directory: commandDirectory)
        let command = NativeMessage(
            schemaVersion: 1,
            messageId: "command-1",
            type: "extension.reload",
            sentAt: Date(timeIntervalSince1970: 1_787_680_800),
            source: "zacksbar-app",
            payload: [:]
        )
        try store.appendCommand(command)

        let inbound = NativeMessage(
            schemaVersion: 1,
            messageId: "health-1",
            type: "health.ping",
            sentAt: Date(timeIntervalSince1970: 1_787_680_801),
            source: "service-worker",
            payload: [
                "component": .string("zacksbar-companion"),
                "version": .string("0.1.0")
            ]
        )

        let result = try runNativeHost(
            input: framed(inbound),
            appSupportDirectory: commandDirectory,
            fakeHome: fakeHome
        )

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.stderr, "")
        XCTAssertEqual(result.messages.count, 2)
        guard result.messages.count == 2 else { return }
        XCTAssertEqual(result.messages[0], command)
        XCTAssertEqual(result.messages[1].type, "health.ping")
        XCTAssertEqual(result.messages[1].messageId, "ack-health-1")
        XCTAssertEqual(result.messages[1].payload["receivedType"], .string("health.ping"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.commandsFile.path))
        XCTAssertEqual(try store.readLatestState()?.latestHealth?.messageId, "health-1")
    }

    private func runNativeHost(input: Data, appSupportDirectory: URL, fakeHome: URL) throws -> NativeHostRunResult {
        let process = Process()
        process.executableURL = nativeHostExecutableURL()

        var environment = ProcessInfo.processInfo.environment
        environment["ZACKSBAR_APP_SUPPORT_DIR"] = appSupportDirectory.path
        environment["HOME"] = fakeHome.path
        environment["CFFIXED_USER_HOME"] = fakeHome.path
        process.environment = environment

        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        try stdin.fileHandleForWriting.write(contentsOf: input)
        try stdin.fileHandleForWriting.close()

        let output = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return NativeHostRunResult(
            exitCode: process.terminationStatus,
            messages: try decodeFrames(output),
            stderr: String(decoding: errorOutput, as: UTF8.self)
        )
    }

    private func nativeHostExecutableURL() -> URL {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return packageRoot
            .appendingPathComponent(".build/debug/zacksbar-native-host")
    }

    private func framed(_ message: NativeMessage) throws -> Data {
        let body = try JSONEncoder.zacksBar.encode(message)
        var length = UInt32(body.count).littleEndian
        var frame = Data(bytes: &length, count: 4)
        frame.append(body)
        return frame
    }

    private func decodeFrames(_ data: Data) throws -> [NativeMessage] {
        var messages: [NativeMessage] = []
        var offset = 0
        while offset < data.count {
            guard offset + 4 <= data.count else {
                throw NativeHostTestError.truncatedLength
            }
            let length = data[offset..<offset + 4].enumerated().reduce(UInt32(0)) { result, pair in
                result | (UInt32(pair.element) << UInt32(pair.offset * 8))
            }
            offset += 4
            let end = offset + Int(length)
            guard end <= data.count else {
                throw NativeHostTestError.truncatedBody
            }
            messages.append(try JSONDecoder.zacksBar.decode(NativeMessage.self, from: data[offset..<end]))
            offset = end
        }
        return messages
    }
}

private struct NativeHostRunResult {
    var exitCode: Int32
    var messages: [NativeMessage]
    var stderr: String
}

private enum NativeHostTestError: Error {
    case truncatedLength
    case truncatedBody
}
