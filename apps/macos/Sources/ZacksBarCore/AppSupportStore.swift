import Foundation

public final class AppSupportStore {
    public let directory: URL
    public let eventsFile: URL
    public let commandsFile: URL

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
    }

    public init(directory: URL, fileManager: FileManager = .default) throws {
        self.directory = directory
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        eventsFile = directory.appendingPathComponent("native-events.jsonl")
        commandsFile = directory.appendingPathComponent("native-commands.jsonl")
    }

    public func appendEvent(_ message: NativeMessage) throws {
        let data = try JSONEncoder.zacksBar.encode(message)
        try appendLine(data, to: eventsFile)
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
}
