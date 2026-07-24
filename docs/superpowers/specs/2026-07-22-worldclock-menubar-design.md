# World Clock Menu Bar App — Design

## Overview

A small native macOS menu bar app. It shows only a 🌎 emoji in the menu bar
(no Dock icon). Clicking it opens a dropdown listing the current time in
three cities: Madrid, Montevideo, and New York. The city list is editable
via a config file without recompiling.

## Architecture

- SwiftUI `App` using `MenuBarExtra` as the sole scene (macOS 13+).
- Packaged as a Swift Package executable target (`Package.swift` +
  `Sources/WorldClockMenuBar/`), not a full `.xcodeproj` — this can be built
  from the terminal via `swift build` and also opened directly in Xcode
  14+, which understands `Package.swift` natively.
- No Dock icon: the built `.app` bundle's `Info.plist` sets
  `LSUIElement = true`.

## Data model / config file

- Location: `~/Library/Application Support/WorldClockMenuBar/cities.json`.
- Format: JSON array of objects, each `{ "name": string, "timezone": string }`,
  where `timezone` is an IANA identifier (e.g. `Europe/Madrid`), not a fixed
  UTC offset, so DST transitions are handled automatically by `TimeZone`.
- Defaults written on first launch if the file doesn't exist:
  ```json
  [
    { "name": "Madrid", "timezone": "Europe/Madrid" },
    { "name": "Montevideo", "timezone": "America/Montevideo" },
    { "name": "New York", "timezone": "America/New_York" }
  ]
  ```
- The user edits this file directly to add/remove/reorder cities. No file
  watching is implemented — the file is re-read fresh every time the
  dropdown menu opens, so edits apply the next time it's clicked.

## UI

- Menu bar label: literal `Text("🌎")`, nothing else.
- Dropdown: one row per city from the config, in file order, formatted as
  24-hour time: `Madrid — 14:32`.
- If a city's local calendar date (in its own timezone) differs from the
  Mac's local calendar date at render time, append the weekday abbreviation:
  `Madrid — 02:15 (Tue)`.

## Refresh behavior

- Config is re-read and all times recomputed on every menu-open event.
- A `Timer`-driven `@State` tick (30s interval) keeps the underlying data
  fresh in case the menu is left open longer than that.

## Build & packaging

1. `swift build -c release` produces the raw executable.
2. Wrap it into `WorldClockMenuBar.app`:
   - `Contents/MacOS/WorldClockMenuBar` (the built binary)
   - `Contents/Info.plist` (bundle id, version, `LSUIElement = true`)
   - `Contents/PkgInfo`
3. Ad-hoc code-sign the bundle (`codesign -s -`), required on Apple Silicon
   even for apps that are never distributed.
4. Copy the signed `.app` to `/Applications`.

## Login item

- On first launch, the app calls `SMAppService.mainApp.register()`
  (macOS 13+ API) to register itself as a login item so it starts
  automatically at login.
- Registration failure is non-fatal (logged, not surfaced as an error UI);
  the user can enable it manually via System Settings → General → Login
  Items if it doesn't take.

## Testing / verification plan

- `swift build` succeeds with no warnings-as-errors issues.
- Launch the built binary directly from the terminal first (before
  installing to `/Applications`) to confirm no crash and check stderr/stdout.
- Sanity-check each IANA timezone's current offset against the shell
  (`TZ=Europe/Madrid date`, etc.) to confirm the computed times match.
- Manual check with the user: click the 🌎 icon and confirm the dropdown
  shows the three cities with correct, correctly-formatted times (and date
  suffix where applicable).

## Out of scope

- No UI for editing the city list (JSON file edited by hand).
- No support for 12-hour format, timezone abbreviations, or a "primary
  city" live display next to the emoji (all considered and explicitly
  declined during design).
- No auto-update mechanism for the app itself.
