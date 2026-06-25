import Foundation

public struct NativeHostManifest: Codable, Equatable {
    public let name: String
    public let description: String
    public let path: String
    public let type: String
    public let allowedOrigins: [String]

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case path
        case type
        case allowedOrigins = "allowed_origins"
    }

    public init(path: String, allowedOrigins: [String]) {
        self.name = "com.zacksbar.native"
        self.description = "ZacksBar Native Messaging Host"
        self.path = path
        self.type = "stdio"
        self.allowedOrigins = allowedOrigins
    }
}
