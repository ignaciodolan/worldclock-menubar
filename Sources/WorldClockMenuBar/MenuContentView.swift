import SwiftUI
import WorldClockMenuBarCore

struct MenuContentView: View {
    @State private var lines: [String] = []
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var configStore: CityConfigStore {
        CityConfigStore(directory: CityConfigStore.defaultDirectory())
    }

    var body: some View {
        Group {
            ForEach(lines, id: \.self) { line in
                Text(line)
            }
        }
        .onAppear(perform: refresh)
        .onReceive(timer) { _ in refresh() }
    }

    private func refresh() {
        guard let cities = try? configStore.loadOrCreateDefaults() else {
            lines = ["Could not read cities.json"]
            return
        }
        let now = Date()
        let localTimeZone = TimeZone.current
        lines = cities.map { CityTimeFormatter.format(city: $0, now: now, localTimeZone: localTimeZone) }
    }
}
