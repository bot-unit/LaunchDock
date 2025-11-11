# Persistence

This document details how LaunchDock persists user configuration to disk.

## Location

All JSON files are stored in:

- `~/Documents/LaunchDockConfig/`

The directory is created at app startup when the `StorageService` is initialized.

## Files

- `folders.json`
  - Type: `Array<VirtualFolder>`
  - Purpose: Stores virtual folders and their associated `appPaths`.
- `hidden-apps.json`
  - Type: `Array<String>` (unique paths)
  - Purpose: Stores hidden application paths.
- `custom-apps.json`
  - Type: `Array<CustomAppEntry>` (new format) or `Array<String>` (legacy)
  - Purpose: Stores manually added applications.

### CustomAppEntry (new format)

```json
{
  "path": "/absolute/path/to/Foo.app",
  "bookmark": "BASE64_SECURITY_SCOPED_BOOKMARK"
}
```

- `path`: Absolute path to the `.app` bundle.
- `bookmark`: Base64-encoded `Data` of a security-scoped bookmark. Can be `null` when not available (legacy entries or creation failure). Bookmarks allow persistent access to files outside standard locations under App Sandbox.

## Behavior

- On startup or when user triggers "Refresh":
  1. `ApplicationManager.loadApplications()` scans standard system app directories.
  2. It calls `loadPersistedCustomApps()` which reads `custom-apps.json`.
  3. For each entry:
     - Resolves the bookmark with `URL(resolvingBookmarkData: .withSecurityScope)` when present.
     - Calls `startAccessingSecurityScopedResource()` for the URL.
     - If the file exists and metadata is readable, creates `AppInfo` and adds it.
     - If the bookmark is stale, regenerates and saves it.
  4. Entries whose files no longer exist are removed from `custom-apps.json`.

- When a user adds a custom app (dialog or drag-and-drop):
  - A security-scoped bookmark is created and saved in `custom-apps.json`.
  - The app appears immediately in the grid and persists across restarts.

## Import/Export

- Current export/import via Settings supports `folders` and `hiddenApps`.
- Support for exporting/importing `customApps` (with bookmarks) is available in `StorageService`, but UI wiring is pending.
  - Export signature supports `customAppPaths`.
  - Import returns `(folders, hiddenApps, customApps)`.
- Next step: extend `SettingsView`/`FolderManager` to include `customApps` in the export/import flow.

## Edge Cases

- Moved or deleted custom apps: automatically pruned on next load.
- Stale bookmarks: automatically refreshed when possible.
- Missing read access: if bookmark cannot be resolved and file is inaccessible, the entry is skipped.
