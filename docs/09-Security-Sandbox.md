# Security & Sandbox

LaunchDock runs under the macOS App Sandbox.

## Entitlements

- `com.apple.security.app-sandbox`: Enables sandbox
- `com.apple.security.network.client`: Allows outbound client networking (future use)
- `com.apple.security.files.user-selected.read-only`
- `com.apple.security.files.user-selected.read-write`

## Rationale

User-selected file access entitlements allow the open panel and drag & drop to pass URLs.
Security-scoped bookmarks extend access across launches for custom application bundles outside standard directories.

## Bookmark Lifecycle

1. User selects or drops `.app` → create bookmark (`URL.bookmarkData(withSecurityScope...)`).
2. On next launch, resolve bookmark (`URL(resolvingBookmarkData:options:.withSecurityScope...)`).
3. Call `startAccessingSecurityScopedResource()`, create `AppInfo`.
4. If bookmark stale, recreate and persist.
5. When finished, call `stopAccessingSecurityScopedResource()` (handled via `defer`).

## Risks & Mitigations

- Stale bookmarks: auto-refresh on load
- Deleted apps: pruned from `custom-apps.json`
- Missing entitlements: would break access to non-standard locations (monitor during build settings changes)
