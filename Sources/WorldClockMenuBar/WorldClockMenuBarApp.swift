import SwiftUI

@main
struct WorldClockMenuBarApp: App {
    init() {
        LoginItemRegistrar.registerIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra("🌎") {
            MenuContentView()
        }
        .menuBarExtraStyle(.menu)
    }
}
