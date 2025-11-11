# Overview

LaunchDock is a macOS application that provides a customizable grid and folder-based organization layer over installed applications. Users can:

- Group apps into virtual folders
- Hide apps from the main view
- Add custom applications outside standard directories (with security-scoped bookmark persistence)
- Drag & drop .app bundles directly onto the interface

## Goals

- Fast visual access to frequently used tools
- Lightweight persistence with transparent JSON formats
- Extensible architecture (Services + ViewModels + Views separation)

## Non-Goals

- Deep system management or uninstall features
- App store / distribution management

## High-Level Stack

- Language: Swift + SwiftUI
- Persistence: JSON files + security scoped bookmarks
- Sandbox: macOS App Sandbox with user-selected read/write entitlements

## Key Differentiators

1. Virtual folder abstraction without moving app bundles.
2. Manual inclusion of non-standard / portable apps via bookmarks.
3. Clear documentation-driven development workflow.

## Future Extensions (Examples)

- Favorites or Pinned section
- Tags / multi-categorization
- Quick search improvements (fuzzy match, tokenization)
- Multi-config profile switching
