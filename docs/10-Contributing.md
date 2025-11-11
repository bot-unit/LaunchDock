# Contributing

This guide describes how to safely introduce changes to LaunchDock and keep documentation authoritative.

## Principles

- Any functional change must be accompanied by documentation updates.
- Documentation is a first-class artifact and should be kept in sync with code.
- Small, low-risk adjacent improvements (tests, types, docs) are encouraged alongside code changes.

## Workflow

1. Create or update a design note (optional for small changes).
2. Update code.
3. Update documentation:
   - `docs/05-Persistence.md` for persistence/JSON format changes.
   - `docs/04-Services.md` for new service contracts or behavior.
   - `docs/06-UI-Views.md` for new screens or view props.
   - `docs/02-Architecture.md` if architecture or data flow changes.
4. Add a changelog entry in `docs/README.md`.
5. Verify Build/Typecheck and run any available tests.
6. If adding settings that affect exported config, update import/export docs.

## Commit Messages

- Use concise imperative style: "Add bookmark persistence for custom apps".
- Reference affected docs files when relevant.

## Review Checklist

- [ ] Code builds and passes type checks
- [ ] Docs updated (persistence, services, views, architecture)
- [ ] User-visible changes described in changelog
- [ ] Edge cases considered (deleted files, sandbox access, staleness)

## Adding/Changing Persistence

- Update `StorageService` with new save/load functions.
- Document file format and migration in `docs/05-Persistence.md`.
- Ensure callers update on load and clean missing entries if necessary.

## Import/Export Updates

- Keep export signatures backward-compatible when possible (defaulted arguments).
- Clearly document any new fields in `docs/08-Import-Export.md`.
