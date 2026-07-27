import Foundation

public enum CityTimeFormatter {
    public static func format(city: City, now: Date, localTimeZone: TimeZone) -> String {
        guard let cityZone = TimeZone(identifier: city.timezone) else {
            return "\(city.name) — invalid timezone"
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = cityZone
        let timeString = timeFormatter.string(from: now)

        var cityCalendar = Calendar(identifier: .gregorian)
        cityCalendar.timeZone = cityZone
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = localTimeZone

        let cityDay = cityCalendar.dateComponents([.year, .month, .day], from: now)
        let localDay = localCalendar.dateComponents([.year, .month, .day], from: now)

        guard cityDay.year == localDay.year, cityDay.month == localDay.month, cityDay.day == localDay.day else {
            let weekdayFormatter = DateFormatter()
            weekdayFormatter.dateFormat = "EEE"
            weekdayFormatter.timeZone = cityZone
            let weekday = weekdayFormatter.string(from: now)
            return "\(city.name) — \(timeString) (\(weekday))"
        }

        return "\(city.name) — \(timeString)"
    }
}
