# LaunchDock

macOS application for customizable grid and folder-based organization of applications.

## Documentation

Comprehensive project documentation is located in the [`docs/`](docs/) directory:

- [Architecture](docs/02-Architecture.md) — Layers, data flows, dependencies
- [Persistence](docs/05-Persistence.md) — JSON formats and security-scoped bookmarks
- [Contributing](docs/10-Contributing.md) — How to safely introduce changes

See [`docs/README.md`](docs/README.md) for the complete index.

## Quick Start

1. Open `LaunchDock.xcodeproj` in Xcode
2. Build and run (⌘R)
3. Add custom apps via the "Add Custom Application" button or drag & drop `.app` bundles

## Features

- Virtual folder organization without moving app bundles
- Hide/show apps
- Manually add apps via button or drag & drop `.app` bundles
- Security-scoped bookmark persistence for custom apps
- Export/import configuration
- Quick hide with ESC key (when no modal windows are open)
- Optional update check for installed applications (requires outbound network permission)

## Network Permissions

LaunchDock performs an optional update check (when you trigger the updates sheet) which fetches metadata remotely. For this feature to work, the application must have permission for outbound network connections. If you use a firewall or privacy tool, allow LaunchDock to initiate outgoing requests; otherwise the update check will silently report no data.

## License

TBD
