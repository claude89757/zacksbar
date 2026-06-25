import Foundation

public struct ChromeExtensionID: RawRepresentable, Equatable, Codable {
    public let rawValue: String

    public init(_ value: String) throws {
        guard value.range(of: #"^[a-p]{32}$"#, options: .regularExpression) != nil else {
            throw NativeHostInstallerError.invalidExtensionID
        }
        rawValue = value
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public enum NativeHostInstallerError: Error, Equatable {
    case invalidExtensionID
    case missingNativeHostExecutable(String)
}

public struct NativeHostInstallResult: Equatable {
    public var manifestURL: URL
    public var nativeHostExecutable: URL
    public var extensionID: ChromeExtensionID
}

public final class NativeHostInstaller {
    public let manifestURL: URL
    private let fileManager: FileManager

    public init(
        manifestURL: URL = DiagnosticPaths.defaultChromeNativeHostManifest,
        fileManager: FileManager = .default
    ) {
        self.manifestURL = manifestURL
        self.fileManager = fileManager
    }

    public func install(
        nativeHostExecutable: URL,
        extensionID: ChromeExtensionID
    ) throws -> NativeHostInstallResult {
        guard fileManager.fileExists(atPath: nativeHostExecutable.path) else {
            throw NativeHostInstallerError.missingNativeHostExecutable(nativeHostExecutable.path)
        }

        let manifest = NativeHostManifest(
            path: nativeHostExecutable.path,
            allowedOrigins: ["chrome-extension://\(extensionID.rawValue)/"]
        )
        let directory = manifestURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder.zacksBar.encode(manifest)
        try data.write(to: manifestURL, options: [.atomic])
        return NativeHostInstallResult(
            manifestURL: manifestURL,
            nativeHostExecutable: nativeHostExecutable,
            extensionID: extensionID
        )
    }
}
