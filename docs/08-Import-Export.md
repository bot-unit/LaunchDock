# Import & Export

This doc explains how configuration export and import work.

## Current State

- Export/Import UI currently handles:
  - folders
  - hiddenApps
- `StorageService` supports `customApps` in the underlying helpers, but the Settings UI doesn’t pass them yet.

## Planned Extension

- Extend `SettingsView`/`FolderManager` to:
  - Include `customApps` in export payload (paths or entries)
  - On import, merge or replace current configuration and persist

## Compatibility

- Keep arguments backward-compatible by using default values in function signatures.
- When adding new fields, ensure import tolerates absence (older files) and presence (newer files).
