import XCTest
@testable import WorldClockMenuBarCore

final class CityTimeFormatterTests: XCTestCase {
    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int, timeZoneIdentifier: String) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier)!
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: components)!
    }

    func test_format_sameCalendarDay_omitsWeekday() {
        let now = makeDate(year: 2026, month: 1, day: 14, hour: 10, minute: 30, timeZoneIdentifier: "America/Montevideo")
        let city = City(name: "Montevideo", timezone: "America/Montevideo")
        let localTimeZone = TimeZone(identifier: "America/Montevideo")!

        let result = CityTimeFormatter.format(city: city, now: now, localTimeZone: localTimeZone)

        XCTAssertEqual(result, "Montevideo — 10:30")
    }

    func test_format_differentCalendarDay_appendsWeekday() {
        // 2026-01-14 02:15 in Madrid (CET, UTC+1) is 2026-01-13 20:15 in New York (EST, UTC-5).
        let now = makeDate(year: 2026, month: 1, day: 14, hour: 2, minute: 15, timeZoneIdentifier: "Europe/Madrid")
        let city = City(name: "Madrid", timezone: "Europe/Madrid")
        let localTimeZone = TimeZone(identifier: "America/New_York")!

        let result = CityTimeFormatter.format(city: city, now: now, localTimeZone: localTimeZone)

        XCTAssertEqual(result, "Madrid — 02:15 (Wed)")
    }

    func test_format_differentCalendarDay_cityBehindLocal_appendsWeekday() {
        // 2026-01-13 20:15 in New York (EST, UTC-5) is 2026-01-14 02:15 in Madrid (CET, UTC+1).
        let now = makeDate(year: 2026, month: 1, day: 13, hour: 20, minute: 15, timeZoneIdentifier: "America/New_York")
        let city = City(name: "New York", timezone: "America/New_York")
        let localTimeZone = TimeZone(identifier: "Europe/Madrid")!

        let result = CityTimeFormatter.format(city: city, now: now, localTimeZone: localTimeZone)

        XCTAssertEqual(result, "New York — 20:15 (Tue)")
    }

    func test_format_invalidTimezone_returnsErrorMessage() {
        let city = City(name: "Nowhere", timezone: "Not/AZone")
        let localTimeZone = TimeZone(identifier: "UTC")!

        let result = CityTimeFormatter.format(city: city, now: Date(timeIntervalSince1970: 0), localTimeZone: localTimeZone)

        XCTAssertEqual(result, "Nowhere — invalid timezone")
    }
}
