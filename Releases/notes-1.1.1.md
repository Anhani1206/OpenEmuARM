## What's New in 1.1.1

## Bug Fixes

- Arcade system now appears in the sidebar after installing an Arcade core
- Game lookup now falls back to the local database and libretro when ScreenScraper is unavailable or returns an error
- ScreenScraper credentials in Preferences are now verified when you save them — no more false green checkmark
- Fixed several app hangs on macOS Sequoia (input monitoring alert, XPC game launch)
- Fixed a crash on first install when a core update error appeared at launch
- Fixed a hang in the BIOS preferences panel

## Under the Hood

- Crash reporting now covers the XPC helper process and core plugin binaries
