import Foundation

public struct CityConfigStore {
    public static let defaultCities: [City] = [
        City(name: "Madrid", timezone: "Europe/Madrid"),
        City(name: "Montevideo", timezone: "America/Montevideo"),
        City(name: "New York", timezone: "America/New_York"),
    ]

    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public init(directory: URL) {
        self.fileURL = directory.appendingPathComponent("cities.json")
    }

    public static func defaultDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("WorldClockMenuBar", isDirectory: true)
    }

    @discardableResult
    public func loadOrCreateDefaults() throws -> [City] {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([City].self, from: data)
        }
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(Self.defaultCities)
        try data.write(to: fileURL)
        return Self.defaultCities
    }
}
