import XCTest
@testable import WorldClockMenuBarCore

final class CityConfigStoreTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func test_loadOrCreateDefaults_writesDefaultsWhenFileMissing() throws {
        let store = CityConfigStore(directory: tempDirectory)

        let cities = try store.loadOrCreateDefaults()

        XCTAssertEqual(cities, CityConfigStore.defaultCities)
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.fileURL.path))
    }

    func test_loadOrCreateDefaults_readsExistingFile() throws {
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        let fileURL = tempDirectory.appendingPathComponent("cities.json")
        let custom = [City(name: "Tokyo", timezone: "Asia/Tokyo")]
        try JSONEncoder().encode(custom).write(to: fileURL)

        let store = CityConfigStore(directory: tempDirectory)
        let cities = try store.loadOrCreateDefaults()

        XCTAssertEqual(cities, custom)
    }
}
