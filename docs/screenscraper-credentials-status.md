# ScreenScraper API integration

## Current status

The ScreenScraper developer API is configured locally and was verified successfully on 21 August 2026 using the official infrastructure endpoint. The application uses the canonical API host:

```
https://api.screenscraper.fr/api2/
```

The implementation sends the required developer fields (`devid`, `devpassword`, and `softname`) for verification and game lookups. User account fields (`ssid` and `sspassword`) are optional at the API level and are supplied by the Cover Art preference pane when the player signs in.

## Release behavior

`OpenEmu/ScreenScraperDevCredentials.swift` contains the local developer configuration used when this project is built. It is intentionally excluded from source control and must never be copied into documentation, backups, commits, pull requests, or releases as a source file.

Builds made on the configured release machine include the integration. A release maintainer must keep the local credentials file in place while creating the final app build, but must not publish its contents.

## User setup

In the app, open **Preferences → Cover Art** and enter the ScreenScraper member username and normal account password. The password is stored in the macOS Keychain; it is not stored in the project source.

## Maintenance checklist

- Keep the API host as `api.screenscraper.fr`.
- Verify the developer connection with `ssinfraInfos.php` before a release.
- Never enable developer debug mode in normal user flows; ScreenScraper limits it to 100 uses per day.
- If developer credentials are changed or revoked, update only the local credentials file and verify again.
