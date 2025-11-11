# Adding Custom Applications

You can add apps that are not in standard directories via:

- Add Custom Application dialog
- Drag & Drop a `.app` bundle into the app

## Flow

```text
User action → URL to .app
  → ApplicationManager.addCustomApplication(url)
    → Create security-scoped bookmark
    → Create AppInfo
    → Append to `applications` (no duplicates)
    → Save to `custom-apps.json`
```

## Notes

- Apps must be `.app` bundles
- If the file is moved or deleted, it will disappear on next refresh/start
- Bookmarks are refreshed when detected stale
