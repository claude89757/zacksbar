import Foundation

public struct LatestAppState: Codable, Equatable {
    public var updatedAt: Date
    public var latestAvailability: NativeMessage?
    public var latestCaptcha: NativeMessage?
    public var latestHealth: NativeMessage?
    public var latestMessageType: String

    public init(
        updatedAt: Date,
        latestAvailability: NativeMessage? = nil,
        latestCaptcha: NativeMessage? = nil,
        latestHealth: NativeMessage? = nil,
        latestMessageType: String
    ) {
        self.updatedAt = updatedAt
        self.latestAvailability = latestAvailability
        self.latestCaptcha = latestCaptcha
        self.latestHealth = latestHealth
        self.latestMessageType = latestMessageType
    }
}

public final class AppSupportStore {
    public let directory: URL
    public let eventsFile: URL
    public let commandsFile: URL
    public let latestStateFile: URL

    public init(fileManager: FileManager = .default) throws {
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        directory = base.appendingPathComponent("ZacksBar", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        eventsFile = directory.appendingPathComponent("native-events.jsonl")
        commandsFile = directory.appendingPathComponent("native-commands.jsonl")
        latestStateFile = directory.appendingPathComponent("latest-state.json")
    }

    public init(directory: URL, fileManager: FileManager = .default) throws {
        self.directory = directory
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        eventsFile = directory.appendingPathComponent("native-events.jsonl")
        commandsFile = directory.appendingPathComponent("native-commands.jsonl")
        latestStateFile = directory.appendingPathComponent("latest-state.json")
    }

    public func appendEvent(_ message: NativeMessage) throws {
        let data = try JSONEncoder.zacksBar.encode(message)
        try appendLine(data, to: eventsFile)
        try updateLatestState(with: message)
    }

    public func readLatestState() throws -> LatestAppState? {
        guard FileManager.default.fileExists(atPath: latestStateFile.path) else { return nil }
        let data = try Data(contentsOf: latestStateFile)
        return try JSONDecoder.zacksBar.decode(LatestAppState.self, from: data)
    }

    private func appendLine(_ data: Data, to file: URL) throws {
        if !FileManager.default.fileExists(atPath: file.path) {
            FileManager.default.createFile(atPath: file.path, contents: nil)
        }
        let handle = try FileHandle(forWritingTo: file)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
        try handle.write(contentsOf: Data([0x0A]))
    }

    private func updateLatestState(with message: NativeMessage) throws {
        guard ["availability.updated", "captcha.detected", "health.ping"].contains(message.type) else {
            return
        }

        var state = try readLatestState() ?? LatestAppState(
            updatedAt: message.sentAt,
            latestMessageType: message.type
        )
        state.updatedAt = message.sentAt
        state.latestMessageType = message.type

        switch message.type {
        case "availability.updated":
            state.latestAvailability = message
        case "captcha.detected":
            state.latestCaptcha = message
        case "health.ping":
            state.latestHealth = message
        default:
            break
        }

        let data = try JSONEncoder.zacksBar.encode(state)
        try data.write(to: latestStateFile, options: [.atomic])
    }
}
