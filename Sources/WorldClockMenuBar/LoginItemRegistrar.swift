import ServiceManagement

enum LoginItemRegistrar {
    static func registerIfNeeded() {
        guard SMAppService.mainApp.status != .enabled else { return }
        do {
            try SMAppService.mainApp.register()
        } catch {
            print("WorldClockMenuBar: login item registration failed: \(error)")
        }
    }
}
