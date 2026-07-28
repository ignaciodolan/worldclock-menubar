# WorldClock Menu Bar

A tiny macOS menu bar app. Click the 🌎 icon to see the current time in Madrid, Montevideo, and New York.

## Install

```bash
git clone https://github.com/ignaciodolan/worldclock-menubar.git
cd worldclock-menubar
./scripts/build_and_install.sh
open /Applications/WorldClockMenuBar.app
```

This builds the app, ad-hoc signs it, and installs it to `/Applications`. It also registers itself as a login item, so it starts automatically next time you log in.

Requires macOS 13+ and Xcode (for the Swift toolchain).

## Configuring cities

Edit `~/Library/Application Support/WorldClockMenuBar/cities.json` (created with the defaults below on first launch):

```json
[
  { "name": "Madrid", "timezone": "Europe/Madrid" },
  { "name": "Montevideo", "timezone": "America/Montevideo" },
  { "name": "New York", "timezone": "America/New_York" }
]
```

`timezone` must be a valid [IANA time zone identifier](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). Add, remove, or reorder cities as you like — changes apply the next time you open the menu.

## Development

```bash
swift build
swift test
```

See `docs/superpowers/specs/` and `docs/superpowers/plans/` for the original design spec and implementation plan.
