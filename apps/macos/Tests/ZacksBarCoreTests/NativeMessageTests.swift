import XCTest
@testable import ZacksBarCore

final class NativeMessageTests: XCTestCase {
    func testDecodesAvailabilityMessage() throws {
        let json = """
        {
          "schemaVersion": 1,
          "messageId": "test-1",
          "type": "availability.updated",
          "sentAt": "2026-06-25T12:00:00Z",
          "source": "content-script",
          "payload": {"venue":"bawtt tennis"}
        }
        """.data(using: .utf8)!

        let message = try JSONDecoder.zacksBar.decode(NativeMessage.self, from: json)
        XCTAssertEqual(message.schemaVersion, 1)
        XCTAssertEqual(message.type, "availability.updated")
        XCTAssertEqual(message.payload["venue"]?.stringValue, "bawtt tennis")
    }
}
