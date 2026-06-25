import Foundation

public enum PrivacyRedactor {
    public static func redact(_ input: String) -> String {
        var output = input
        output = output.replacingOccurrences(of: #"https?://[^\s\?]+(?:\?[^\s]+)?"#, with: "[redacted-url]", options: .regularExpression)
        output = output.replacingOccurrences(of: #"\b1[3-9]\d{9}\b"#, with: "[redacted-phone]", options: .regularExpression)
        output = output.replacingOccurrences(of: #"\b\d{10,}\b"#, with: "[redacted-number]", options: .regularExpression)
        return output
    }
}
