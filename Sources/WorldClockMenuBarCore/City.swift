import Foundation

public struct City: Codable, Equatable {
    public let name: String
    public let timezone: String

    public init(name: String, timezone: String) {
        self.name = name
        self.timezone = timezone
    }
}
