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

## UpdateCheckService (planned / optional)

- Queries remote endpoints (e.g. app vendor feeds or metadata URLs) to determine if newer versions are available.
- Requires outbound network permission; deny rules will prevent version data retrieval and the UI will show no updates.
- Implementations should be non-blocking (use async) and cache last results to avoid excessive requests.
