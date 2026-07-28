# World Clock Menu Bar App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS menu bar app that shows a 🌎 icon and, on click, a dropdown listing the current time in Madrid, Montevideo, and New York, driven by an editable JSON config file.

**Architecture:** A SwiftPM package with a pure-logic library target (`WorldClockMenuBarCore`: city model, JSON config load/create-defaults, time formatting) fully covered by XCTest, and a thin SwiftUI executable target (`WorldClockMenuBar`) using `MenuBarExtra` that only wires that logic to the UI. The executable is packaged into a proper `.app` bundle, ad-hoc signed, installed to `/Applications`, and registers itself as a login item via `SMAppService`.

**Tech Stack:** Swift 5.9+, SwiftUI `MenuBarExtra` (macOS 13+), `ServiceManagement.SMAppService`, XCTest, Swift Package Manager (no Xcode project file).

## Global Constraints

- Project root: `~/Projects/radicalroots/worldclock` (already git-initialized).
- Platform floor: macOS 13 (`MenuBarExtra` and `SMAppService` both require it).
- Config file path: `~/Library/Application Support/WorldClockMenuBar/cities.json`.
- Timezones stored as IANA identifiers (e.g. `Europe/Madrid`), never fixed UTC offsets.
- Time format: 24-hour, `"<Name> — HH:mm"`, with `" (EEE)"` appended only when the city's calendar date differs from the Mac's local calendar date.
- Default cities, in order: Madrid (`Europe/Madrid`), Montevideo (`America/Montevideo`), New York (`America/New_York`).
- App bundle identifier: `com.ignaciodolan.worldclockmenubar`; `LSUIElement` must be `true` (no Dock icon).
- Installed app must be ad-hoc code-signed (`codesign --sign -`) before/after copying to `/Applications`.

---

### Task 1: Core package scaffold, City model, and config store

**Files:**
- Create: `Package.swift`
- Create: `.gitignore`
- Create: `Sources/WorldClockMenuBarCore/City.swift`
- Create: `Sources/WorldClockMenuBarCore/CityConfigStore.swift`
- Test: `Tests/WorldClockMenuBarCoreTests/CityConfigStoreTests.swift`

**Interfaces:**
- Consumes: nothing (first task).
- Produces: `public struct City: Codable, Equatable { public let name: String; public let timezone: String; public init(name: String, timezone: String) }`; `public struct CityConfigStore { public static let defaultCities: [City]; public let fileURL: URL; public init(fileURL: URL); public init(directory: URL); public static func defaultDirectory() -> URL; public func loadOrCreateDefaults() throws -> [City] }`. Later tasks use `CityConfigStore.defaultDirectory()` and `loadOrCreateDefaults()`.

- [ ] **Step 1: Create the package scaffold**

`Package.swift`:
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WorldClockMenuBar",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "WorldClockMenuBarCore",
            path: "Sources/WorldClockMenuBarCore"
        ),
        .testTarget(
            name: "WorldClockMenuBarCoreTests",
            dependencies: ["WorldClockMenuBarCore"],
            path: "Tests/WorldClockMenuBarCoreTests"
        ),
    ]
)
```

`.gitignore`:
```
.build/
.swiftpm/
*.xcodeproj
```

`Sources/WorldClockMenuBarCore/City.swift`:
```swift
import Foundation

public struct City: Codable, Equatable {
    public let name: String
    public let timezone: String

    public init(name: String, timezone: String) {
        self.name = name
        self.timezone = timezone
    }
}
```

- [ ] **Step 2: Write the failing test for CityConfigStore**

`Tests/WorldClockMenuBarCoreTests/CityConfigStoreTests.swift`:
```swift
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
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `swift test --package-path ~/Projects/radicalroots/worldclock --filter CityConfigStoreTests`
Expected: FAIL to build — `cannot find 'CityConfigStore' in scope`.

- [ ] **Step 4: Implement CityConfigStore**

`Sources/WorldClockMenuBarCore/CityConfigStore.swift`:
```swift
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
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `swift test --package-path ~/Projects/radicalroots/worldclock --filter CityConfigStoreTests`
Expected: `Test Suite 'CityConfigStoreTests' passed` — both tests pass.

- [ ] **Step 6: Commit**

```bash
cd ~/Projects/radicalroots/worldclock
git add Package.swift .gitignore Sources/WorldClockMenuBarCore Tests/WorldClockMenuBarCoreTests
git commit -m "Add City model and CityConfigStore with JSON config load/defaults"
```

---

### Task 2: CityTimeFormatter

**Files:**
- Create: `Sources/WorldClockMenuBarCore/CityTimeFormatter.swift`
- Test: `Tests/WorldClockMenuBarCoreTests/CityTimeFormatterTests.swift`

**Interfaces:**
- Consumes: `City` from Task 1 (`name`, `timezone` fields).
- Produces: `public enum CityTimeFormatter { public static func format(city: City, now: Date, localTimeZone: TimeZone) -> String }`. Task 3's `MenuContentView` calls this directly.

- [ ] **Step 1: Write the failing test**

`Tests/WorldClockMenuBarCoreTests/CityTimeFormatterTests.swift`:
```swift
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
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `swift test --package-path ~/Projects/radicalroots/worldclock --filter CityTimeFormatterTests`
Expected: FAIL to build — `cannot find 'CityTimeFormatter' in scope`.

- [ ] **Step 3: Implement CityTimeFormatter**

`Sources/WorldClockMenuBarCore/CityTimeFormatter.swift`:
```swift
import Foundation

public enum CityTimeFormatter {
    public static func format(city: City, now: Date, localTimeZone: TimeZone) -> String {
        let cityZone = TimeZone(identifier: city.timezone) ?? TimeZone(identifier: "GMT")!

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
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `swift test --package-path ~/Projects/radicalroots/worldclock --filter CityTimeFormatterTests`
Expected: `Test Suite 'CityTimeFormatterTests' passed` — both tests pass.

- [ ] **Step 5: Run the full test suite**

Run: `swift test --package-path ~/Projects/radicalroots/worldclock`
Expected: All tests in `WorldClockMenuBarCoreTests` pass (4 tests total from Tasks 1–2).

- [ ] **Step 6: Commit**

```bash
cd ~/Projects/radicalroots/worldclock
git add Sources/WorldClockMenuBarCore/CityTimeFormatter.swift Tests/WorldClockMenuBarCoreTests/CityTimeFormatterTests.swift
git commit -m "Add CityTimeFormatter with cross-day weekday suffix logic"
```

---

### Task 3: MenuBarExtra executable UI

**Files:**
- Modify: `Package.swift` (add executable target)
- Create: `Sources/WorldClockMenuBar/WorldClockMenuBarApp.swift`
- Create: `Sources/WorldClockMenuBar/MenuContentView.swift`

**Interfaces:**
- Consumes: `CityConfigStore.defaultDirectory()`, `CityConfigStore(directory:).loadOrCreateDefaults()`, `CityTimeFormatter.format(city:now:localTimeZone:)` from Tasks 1–2.
- Produces: `@main struct WorldClockMenuBarApp: App` (executable entry point), used only by the OS/launcher — no later task calls it directly except Task 4, which adds an `init()` call.

- [ ] **Step 1: Add the executable target to Package.swift**

Modify `Package.swift` — add this entry to the `targets` array (after the `WorldClockMenuBarCore` target, before `testTarget`):
```swift
        .executableTarget(
            name: "WorldClockMenuBar",
            dependencies: ["WorldClockMenuBarCore"],
            path: "Sources/WorldClockMenuBar"
        ),
```

- [ ] **Step 2: Create the menu content view**

`Sources/WorldClockMenuBar/MenuContentView.swift`:
```swift
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
```

- [ ] **Step 3: Create the app entry point**

`Sources/WorldClockMenuBar/WorldClockMenuBarApp.swift`:
```swift
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
```

- [ ] **Step 4: Build and verify it compiles**

Run: `swift build --package-path ~/Projects/radicalroots/worldclock`
Expected: `Build complete!` with no errors.

- [ ] **Step 5: Manually verify the menu bar UI**

Run in background: `~/Projects/radicalroots/worldclock/.build/debug/WorldClockMenuBar &`

Ask the user to look at their menu bar for the 🌎 icon, click it, and confirm the dropdown shows three lines — Madrid, Montevideo, New York — each with a plausible current time in `HH:mm` format (and a `(EEE)` suffix on any city whose calendar date differs from their Mac's local date right now).

Once confirmed, stop the process: `pkill -f ".build/debug/WorldClockMenuBar"`

- [ ] **Step 6: Commit**

```bash
cd ~/Projects/radicalroots/worldclock
git add Package.swift Sources/WorldClockMenuBar
git commit -m "Add MenuBarExtra UI wiring core logic to a 🌎 menu bar dropdown"
```

---

### Task 4: Login item registration

**Files:**
- Create: `Sources/WorldClockMenuBar/LoginItemRegistrar.swift`
- Modify: `Sources/WorldClockMenuBar/WorldClockMenuBarApp.swift`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `enum LoginItemRegistrar { static func registerIfNeeded() }`, called once from `WorldClockMenuBarApp.init()`.

- [ ] **Step 1: Create the login item registrar**

`Sources/WorldClockMenuBar/LoginItemRegistrar.swift`:
```swift
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
```

- [ ] **Step 2: Call it on app launch**

Modify `Sources/WorldClockMenuBar/WorldClockMenuBarApp.swift`:
```swift
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
```

- [ ] **Step 3: Build and verify it compiles**

Run: `swift build --package-path ~/Projects/radicalroots/worldclock`
Expected: `Build complete!` with no errors.

Note: `SMAppService.mainApp.register()` only succeeds for an app launched from a proper signed bundle in `/Applications` — it will silently no-op or log a failure when run as a loose `.build/debug` binary. Functional verification of this happens in Task 6, after Task 5 installs the real `.app`.

- [ ] **Step 4: Commit**

```bash
cd ~/Projects/radicalroots/worldclock
git add Sources/WorldClockMenuBar/LoginItemRegistrar.swift Sources/WorldClockMenuBar/WorldClockMenuBarApp.swift
git commit -m "Register app as a login item via SMAppService on launch"
```

---

### Task 5: App bundle packaging and install script

**Files:**
- Create: `Info.plist`
- Create: `scripts/build_and_install.sh`

**Interfaces:**
- Consumes: the `WorldClockMenuBar` executable produced by `swift build -c release` (Tasks 3–4).
- Produces: `/Applications/WorldClockMenuBar.app`, a signed, launchable app bundle. Task 6 launches it directly by path.

- [ ] **Step 1: Create Info.plist**

`Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>WorldClockMenuBar</string>
    <key>CFBundleIdentifier</key>
    <string>com.ignaciodolan.worldclockmenubar</string>
    <key>CFBundleName</key>
    <string>WorldClockMenuBar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 2: Create the build/install script**

`scripts/build_and_install.sh`:
```bash
#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="WorldClockMenuBar"
BUILD_CONFIG="release"
APP_BUNDLE="$ROOT_DIR/.build/$APP_NAME.app"
INSTALL_PATH="/Applications/$APP_NAME.app"

echo "Building $APP_NAME ($BUILD_CONFIG)..."
swift build --package-path "$ROOT_DIR" -c "$BUILD_CONFIG"

BINARY_PATH="$ROOT_DIR/.build/$BUILD_CONFIG/$APP_NAME"
if [ ! -f "$BINARY_PATH" ]; then
    echo "Build failed: binary not found at $BINARY_PATH" >&2
    exit 1
fi

echo "Assembling app bundle at $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
printf 'APPL????' > "$APP_BUNDLE/Contents/PkgInfo"

echo "Code-signing (ad-hoc)..."
codesign --force --sign - "$APP_BUNDLE"

echo "Installing to $INSTALL_PATH..."
if [ -d "$INSTALL_PATH" ]; then
    rm -rf "$INSTALL_PATH"
fi
cp -R "$APP_BUNDLE" "$INSTALL_PATH"

echo "Done. Launch with: open \"$INSTALL_PATH\""
```

- [ ] **Step 3: Make it executable and run it**

Run:
```bash
chmod +x ~/Projects/radicalroots/worldclock/scripts/build_and_install.sh
~/Projects/radicalroots/worldclock/scripts/build_and_install.sh
```
Expected: ends with `Done. Launch with: open "/Applications/WorldClockMenuBar.app"`, no errors.

- [ ] **Step 4: Verify the installed bundle is signed and well-formed**

Run: `codesign -dv /Applications/WorldClockMenuBar.app`
Expected: exits 0 and prints signature info (e.g. `Signature=adhoc`).

Run: `/usr/libexec/PlistBuddy -c "Print :LSUIElement" /Applications/WorldClockMenuBar.app/Contents/Info.plist`
Expected: `true`.

- [ ] **Step 5: Commit**

```bash
cd ~/Projects/radicalroots/worldclock
git add Info.plist scripts/build_and_install.sh
git commit -m "Add Info.plist and build_and_install.sh for packaging to /Applications"
```

---

### Task 6: End-to-end verification (manual checkpoint)

**Files:** none — verification only, no code changes.

**Interfaces:**
- Consumes: the installed `/Applications/WorldClockMenuBar.app` from Task 5.
- Produces: nothing for later tasks — this is the final acceptance check from the spec's testing plan.

- [ ] **Step 1: Launch the installed app**

Run: `open /Applications/WorldClockMenuBar.app`

- [ ] **Step 2: Confirm the process is running**

Run: `pgrep -fl WorldClockMenuBar`
Expected: one matching process line.

- [ ] **Step 3: Ask the user to verify the dropdown**

Ask the user to click the 🌎 icon in their menu bar and confirm:
- No other icon/text appears next to 🌎, and no Dock icon appeared.
- Three rows show: Madrid, Montevideo, New York, each `HH:mm` in 24-hour format.
- Any city whose calendar date differs right now from the Mac's local date shows a `(EEE)` suffix.

- [ ] **Step 4: Ask the user to verify the login item**

Ask the user to open System Settings → General → Login Items and confirm `WorldClockMenuBar` is listed and enabled.

- [ ] **Step 5: Record the outcome**

If everything in Steps 3–4 checks out, the feature is complete — no further commits needed. If something looks wrong, identify which earlier task owns the broken behavior (UI formatting → Task 2/3, login item → Task 4/5) and fix it there before re-running this checkpoint.
