import SwiftUI

@main
struct WorldClockMenuBarApp: App {
    var body: some Scene {
        MenuBarExtra("🌎") {
            MenuContentView()
        }
        .menuBarExtraStyle(.menu)
    }
}
