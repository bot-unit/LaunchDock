# LaunchDock Documentation

Welcome to the LaunchDock project documentation hub. This folder centralizes architectural concepts, configuration persistence, development workflow, and future extension guidelines.

## Index

- 01-Overview.md – High-level product and goals
- 02-Architecture.md – Layered architecture, data flow, dependencies (extended)
- 03-Models.md – Data structures and invariants
- 04-Services.md – Responsibilities and contracts
- 05-Persistence.md – JSON files + security-scoped bookmarks
- 06-UI-Views.md – View composition and state propagation
- 07-Adding-Custom-Apps.md – Manual add & drag-and-drop flow
- 08-Import-Export.md – Config migration & format
- 09-Security-Sandbox.md – Sandboxing specifics & bookmarks
- 10-Contributing.md – Process for introducing changes + documentation rules
- CHANGELOG.md – Detailed chronological changes

> When you add or modify functionality, update the relevant file(s) and append a CHANGELOG entry.

## Quick Facts

- Minimum macOS target: TBD (set in project settings)
- Persistence root: `~/Documents/LaunchDockConfig/`
- JSON files: `folders.json`, `hidden-apps.json`, `custom-apps.json`
- Custom apps persist via security-scoped bookmarks enabling cross-session access.

## Style Guidelines

- Swift naming: lowerCamelCase for properties/functions, UpperCamelCase for types.
- Keep services pure (no UI side-effects).
- ViewModels coordinate; they never hit filesystem directly except via services.

## Extending

When adding a new domain concept (e.g., Favorites):

1. Model extension (update `03-Models.md`).
2. Service or reuse existing service (update `04-Services.md`).
3. Persistence spec (update `05-Persistence.md`).
4. UI integration (update `06-UI-Views.md`).
5. Export/import changes (update `08-Import-Export.md`).
6. Security considerations (update `09-Security-Sandbox.md` if needed).
7. Contributing workflow (update `10-Contributing.md`).

## Changelog

- 2025-11-11: Added structured docs system and bookmark-based custom apps persistence.
- 2025-11-11: Migrated root ARCHITECTURE.md into docs/02-Architecture.md — single source of truth.
