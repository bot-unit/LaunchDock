# Архитектура LaunchDock — Визуальная схема

> Этот документ — единственный источник архитектурной информации для проекта.
> Детали по конфигурации и безопасности вынесены в:
>
> - [05-Persistence.md](05-Persistence.md) — Форматы JSON и политика хранения
> - [10-Contributing.md](10-Contributing.md) — Правила изменения кода и документации

## 📐 Общая схема

```text
┌─────────────────────────────────────────────────────────────┐
│                         LaunchDock App                       │
│                      (macOS Application)                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────┐
              │   LaunchDockApp.swift     │
              │   (Entry Point)            │
              └───────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────┐
              │   AppDelegate.swift       │
              │   (Window Management)      │
              └───────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         VIEWS LAYER                          │
│                     (Presentation / UI)                      │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ ContentView  │    │  HeaderView  │    │ FolderView   │
│              │    │              │    │              │
│ (Main UI)    │    │ (Search +    │    │ (Folders)    │
│              │    │  Settings)   │    │              │
└──────────────┘    └──────────────┘    └──────────────┘
        │                     │                     │
        │                     ▼                     │
        │            ┌──────────────┐              │
        │            │Statistics    │              │
        │            │View          │              │
        │            └──────────────┘              │
        │                                           │
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      VIEWMODELS LAYER                        │
│                 (Business Logic Coordination)                │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Application  │    │   Folder     │    │  Settings    │
│  Manager     │    │   Manager    │    │  Manager     │
│              │    │              │    │              │
│ @Published   │    │ @Published   │    │ @Published   │
│ apps[]       │    │ folders[]    │    │ iconSize     │
│ searchText   │    │ hiddenApps[] │    │ columns      │
└──────────────┘    └──────────────┘    └──────────────┘
        │                     │                     │
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       SERVICES LAYER                         │
│                  (Pure Business Logic)                       │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  AppScanner  │    │  AppLaunch   │    │   Storage    │
│   Service    │    │   Service    │    │   Service    │
│              │    │              │    │              │
│ scanApps()   │    │ launch()     │    │ save()       │
│              │    │              │    │ load()       │
└──────────────┘    └──────────────┘    └──────────────┘
        │                     │                     │
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        MODELS LAYER                          │
│                      (Data Structures)                       │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
            ┌──────────────┐    ┌──────────────┐
            │   AppInfo    │    │ VirtualFolder│
            │              │    │              │
            │ id           │    │ id           │
            │ name         │    │ name         │
            │ url          │    │ appPaths[]   │
            │ icon         │    │ color        │
            └──────────────┘    └──────────────┘
                    │                   │
                    └─────────┬─────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    SYSTEM RESOURCES                          │
│                                                              │
│  • FileSystem (/Applications, /System/Applications)         │
│  • NSWorkspace (App launching)                              │
│  • UserDefaults (Settings)                                  │
│  • JSON Files (Documents/LaunchDockConfig/)                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Поток данных

### Загрузка приложений

```text
User opens app
     │
     ▼
ContentView
     │
     ▼
ApplicationManager.loadApplications()
     │
     ▼
AppScannerService.scanAllApplications()
     │
     ├─► scanDirectory("/Applications")
     ├─► scanDirectory("/System/Applications")
     └─► scanDirectory("~/Applications")
     │
     ▼
[AppInfo] array
     │
     ▼
ApplicationManager.applications = apps
     │
     ▼
@Published triggers UI update
     │
     ▼
ContentView displays apps in grid
```

### Запуск приложения

```text
User clicks app icon
     │
     ▼
ContentView.launchApp(app)
     │
     ▼
ApplicationManager.launchApplication(app)
     │
     ▼
AppLaunchService.launchApplication(app)
     │
     ▼
NSWorkspace.shared.openApplication(at: url)
     │
     ▼
macOS launches app
     │
     ▼
Launcher window hidden (NSApp.hide(nil))
```

### Создание папки

```text
User clicks "Новая папка"
     │
     ▼
ContentView shows FolderCreationSheet
     │
     ▼
User enters name and color
     │
     ▼
FolderManager.addFolder(name, color)
     │
     ▼
folders.append(newFolder)
     │
     ▼
FolderManager.saveFolders()
     │
     ▼
StorageService.saveFolders(folders)
     │
     ▼
JSONEncoder → Data
     │
     ▼
Write to ~/Documents/LaunchDockConfig/folders.json
     │
     ▼
@Published triggers UI update
     │
     ▼
ContentView displays new folder
```

### Drag & Drop приложения

```text
User drags .app file
     │
     ▼
ContentView.onDrop(providers)
     │
     ▼
DragDropHandler.handleDrop(providers)
     │
     ▼
Extract URL from NSItemProvider
     │
     ▼
Validate: is .app? exists? not duplicate?
     │
     ▼
ApplicationManager.addCustomApplication(url)
     │
     ├─► AppScannerService.createAppInfo(from: url)
     ├─► applications.append(newApp)
     └─► StorageService.saveCustomAppEntries(entries[]) → ~/Documents/LaunchDockConfig/custom-apps.json (с security‑scoped bookmarks)
     │
     ▼
@Published triggers UI update
     │
     ▼
ContentView displays new app
```

---

## 📦 Зависимости между компонентами

### ContentView зависит от

- ✅ ApplicationManager (ViewModel)
- ✅ FolderManager (ViewModel)
- ✅ SettingsManager (ViewModel)
- ✅ HeaderView (Component)
- ✅ StatisticsView (Component)
- ✅ DragDropOverlay (Component)
- ✅ DragDropHandler (Utility)
- ✅ FolderView, AppIconView (Components)

### ApplicationManager зависит от

- ✅ AppScannerService
- ✅ AppLaunchService
- ✅ FolderManager (для фильтрации)
- ✅ AppInfo (Model)
- ✅ StorageService (persist custom apps)

### FolderManager зависит от

- ✅ StorageService
- ✅ VirtualFolder (Model)
- ✅ AppInfo (Model)

### AppScannerService зависит от

- ✅ AppInfo (Model)
- ✅ Foundation (FileManager, Bundle)

### AppLaunchService зависит от

- ✅ AppInfo (Model)
- ✅ AppKit (NSWorkspace)

### StorageService зависит от

- ✅ VirtualFolder (Model)
- ✅ Foundation (JSONEncoder/Decoder, FileManager)
- ✅ Файлы конфигурации в ~/Documents/LaunchDockConfig/
  - folders.json — виртуальные папки
  - hidden-apps.json — скрытые приложения
  - custom-apps.json — вручную добавленные приложения

---

## 🎭 Принципы архитектуры

### 1. Separation of Concerns (SoC)

```text
Views        → Только UI, никакой бизнес-логики
ViewModels   → Координация и состояние
Services     → Чистая бизнес-логика
Models       → Только данные
```

### 2. Dependency Inversion

```text
High-level (Views)
    ↓ depends on
ViewModels
    ↓ depends on
Services (abstractions)
    ↓ depends on
Models
```

### 3. Single Responsibility

```text
AppScannerService   → Только сканирование
AppLaunchService    → Только запуск
StorageService      → Только хранение
```

### 4. Don't Repeat Yourself (DRY)

```text
Один сервис используется многими ViewModels
Один компонент используется в разных View
```

---

## 🔍 Где искать код для разных задач

| Задача | Место в коде |
|--------|--------------|
| Изменить UI | `Views/` |
| Добавить новую папку | `FolderManager` → `StorageService` |
| Изменить логику запуска | `AppLaunchService` |
| Добавить новую директорию сканирования | `AppScannerService` |
| Изменить формат хранения | `StorageService` |
| Добавить новое поле в модель | `Models/AppInfo` или `VirtualFolder` |
| Изменить размер иконок | `SettingsManager` |
| Отладить drag & drop | `DragDropHandler` |
| Изменить поиск | `ApplicationManager.filteredApps` |

---

## 🚦 Как добавить новую функцию

### Пример: Добавить "Избранные приложения"

**1. Обновить Model:**

```swift
// Models/AppInfo.swift
struct AppInfo {
    // ...
    var isFavorite: Bool = false  // ← добавить
}
```

**2. Обновить Storage:**

```swift
// Services/StorageService.swift
func saveFavorites(_ favorites: Set<String>) throws {
    try save(Array(favorites), to: "favorites.json")
}

func loadFavorites() throws -> Set<String> {
    let array = try load([String].self, from: "favorites.json") ?? []
    return Set(array)
}
```

**3. Обновить ViewModel:**

```swift
// ViewModels/ApplicationManager.swift
class ApplicationManager: ObservableObject {
    @Published var favoriteAppPaths: Set<String> = []
    private let storage = StorageService()

    func toggleFavorite(_ app: AppInfo) {
        if favoriteAppPaths.contains(app.path) {
            favoriteAppPaths.remove(app.path)
        } else {
            favoriteAppPaths.insert(app.path)
        }
        try? storage.saveFavorites(favoriteAppPaths)
    }

    var favoriteApps: [AppInfo] {
        applications.filter { favoriteAppPaths.contains($0.path) }
    }
}
```

**4. Обновить View:**

```swift
// Views/ContentView.swift
Section(header: Text("Избранное")) {
    ForEach(appManager.favoriteApps) { app in
        AppIconView(app: app, ...)
            .contextMenu {
                Button("Убрать из избранного") {
                    appManager.toggleFavorite(app)
                }
            }
    }
}
```

**Готово!** Каждый слой знает только о своей ответственности.

---

## 📋 Метаданные

**Создано**: 30 октября 2025  
**Последнее обновление**: 11 ноября 2025  
**Версия архитектуры**: 2.1  
**Статус**: Актуально
