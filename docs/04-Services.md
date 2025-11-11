# Services

## AppScannerService

- Scans standard directories for `.app` bundles
- Creates `AppInfo` from URLs

## AppLaunchService

- Launches applications via `NSWorkspace`

## StorageService

- JSON persistence helper (save/load/delete)
- Specialized helpers:
  - `saveFolders(_:)` / `loadFolders()`
  - `saveHiddenApps(_:)` / `loadHiddenApps()`
  - `saveCustomAppEntries(_:)` / `loadCustomAppEntries()` (legacy support for `[String]`)
- Export/Import helpers (folders, hidden apps, custom apps)
