import Foundation
import ZacksBarCore

func readExactBytes(_ count: Int, from handle: FileHandle) throws -> Data? {
    var data = Data()
    while data.count < count {
        let chunk = try handle.read(upToCount: count - data.count) ?? Data()
        if chunk.isEmpty { return data.isEmpty ? nil : data }
        data.append(chunk)
    }
    return data
}

func readNativeMessage(from handle: FileHandle) throws -> NativeMessage? {
    guard let lengthData = try readExactBytes(4, from: handle) else { return nil }
    let bytes = [UInt8](lengthData)
    let length = UInt32(bytes[0])
        | (UInt32(bytes[1]) << 8)
        | (UInt32(bytes[2]) << 16)
        | (UInt32(bytes[3]) << 24)
    guard let body = try readExactBytes(Int(length), from: handle) else { return nil }
    return try JSONDecoder.zacksBar.decode(NativeMessage.self, from: body)
}

func writeNativeMessage(_ message: NativeMessage, to handle: FileHandle) throws {
    let body = try JSONEncoder.zacksBar.encode(message)
    var length = UInt32(body.count).littleEndian
    let lengthData = Data(bytes: &length, count: 4)
    try handle.write(contentsOf: lengthData)
    try handle.write(contentsOf: body)
}

let input = FileHandle.standardInput
let output = FileHandle.standardOutput
let store: AppSupportStore
if let overrideDirectory = ProcessInfo.processInfo.environment["ZACKSBAR_APP_SUPPORT_DIR"],
   !overrideDirectory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
    store = try AppSupportStore(directory: URL(fileURLWithPath: overrideDirectory, isDirectory: true))
} else {
    store = try AppSupportStore()
}

while let message = try readNativeMessage(from: input) {
    try store.appendEvent(message)
    for command in try store.drainCommands() {
        try writeNativeMessage(command, to: output)
    }
    let ack = NativeMessage(
        schemaVersion: 1,
        messageId: "ack-\(message.messageId)",
        type: "health.ping",
        sentAt: Date(),
        source: "native-host",
        payload: ["receivedType": .string(message.type)]
    )
    try writeNativeMessage(ack, to: output)
}
