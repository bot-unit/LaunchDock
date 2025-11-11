# UI Views

## ContentView

- Hosts main grid, folders section, statistics, modals
- Owns sheet presentation states
- After launching an app, the launcher window is automatically hidden (`NSApp.hide(nil)`) for a clean workflow

## FolderView / FolderAppsView

- Display folder summary and inside-folder app listing

## AppIconView

- Renders single application icon and name (optional)
- Context menu for folder assignment / hiding

## AddCustomAppSheet

- Prompts user to pick a `.app`
- Passes `URL` to `ApplicationManager.addCustomApplication(url:)`

## SettingsView

- Controls UI preferences (columns, sizes, dark mode, etc.)
- Export/Import/Reset configuration actions
