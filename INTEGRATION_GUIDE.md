# Инструкция по интеграции новых файлов

## ⚠️ Важно: Добавление файлов в Xcode

Все файлы созданы, но Xcode их не видит. Нужно добавить их в проект:

### Шаг 1: Открыть проект в Xcode
```bash
cd /Users/unit/Projects/xlab/LaunchDock
open LaunchDock.xcodeproj
```

### Шаг 2: Добавить новые папки и файлы

#### Добавить папку Services/
1. В Project Navigator правой кнопкой на `LaunchDock` (группа)
2. "Add Files to LaunchDock..."
3. Выбрать папку `Services/`
4. ✅ **Важно**: Поставить галочку "Create groups"
5. ✅ **Важно**: Убедиться что галочка "Target: LaunchDock" включена
6. Нажать "Add"

Должны добавиться:
- `AppLaunchService.swift`
- `AppScannerService.swift`
- `StorageService.swift`

#### Добавить папку ViewModels/
1. Правой кнопкой на `LaunchDock` (группа)
2. "Add Files to LaunchDock..."
3. Выбрать папку `ViewModels/`
4. ✅ Галочки как выше
5. Нажать "Add"

#### Добавить новые View файлы
1. Правой кнопкой на группу `Views/`
2. "Add Files to LaunchDock..."
3. Выбрать новые файлы:
   - `HeaderView.swift`
   - `StatisticsView.swift`
   - `DragDropOverlay.swift`
4. Нажать "Add"

#### Добавить DragDropHandler
1. Правой кнопкой на группу `Utils/`
2. "Add Files to LaunchDock..."
3. Выбрать `DragDropHandler.swift`
4. Нажать "Add"

### Шаг 3: Проверить Target Membership

Для каждого нового файла:
1. Выбрать файл в Project Navigator
2. Открыть File Inspector (⌥⌘1)
3. В разделе "Target Membership" убедиться что `LaunchDock` отмечен галочкой

### Шаг 4: Собрать проект
```
⌘ + B (Build)
```

Если есть ошибки компиляции - это нормально, их мы исправим на следующих этапах.

---

## 🔧 Следующие шаги рефакторинга

### 1. Рефакторинг ApplicationManager

**Файл**: `Utils/ApplicationManager.swift` → `ViewModels/ApplicationManager.swift`

Заменить методы на вызовы сервисов:

```swift
// БЫЛО:
private func scanDirectory(_ url: URL) -> [AppInfo] {
    // 30+ строк кода
}

// СТАЛО:
private let scanner = AppScannerService()

func loadApplications() {
    DispatchQueue.global(qos: .userInitiated).async {
        let apps = self.scanner.scanAllApplications()
        DispatchQueue.main.async {
            self.applications = apps
            self.isLoading = false
        }
    }
}
```

```swift
// БЫЛО:
func launchApplication(_ app: AppInfo) {
    let configuration = NSWorkspace.OpenConfiguration()
    NSWorkspace.shared.openApplication(at: app.url, configuration: configuration) { (app, error) in
        // ...
    }
}

// СТАЛО:
private let launcher = AppLaunchService()

func launchApplication(_ app: AppInfo) {
    launcher.launchApplication(app)
}
```

### 2. Рефакторинг FolderManager

**Файл**: `Utils/FolderManager.swift` → `ViewModels/FolderManager.swift`

Заменить прямую работу с файлами на StorageService:

```swift
// БЫЛО:
private func saveFolders() {
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(folders)
        try data.write(to: configURL)
    } catch {
        print("Ошибка: \(error)")
    }
}

// СТАЛО:
private let storage = StorageService()

private func saveFolders() {
    do {
        try storage.saveFolders(folders)
    } catch {
        print("Ошибка: \(error)")
    }
}
```

```swift
// БЫЛО:
private func loadFolders() {
    do {
        let data = try Data(contentsOf: configURL)
        let decoder = JSONDecoder()
        folders = try decoder.decode([VirtualFolder].self, from: data)
    } catch {
        folders = []
    }
}

// СТАЛО:
private func loadFolders() {
    do {
        folders = try storage.loadFolders()
    } catch {
        folders = []
    }
}
```

### 3. Упрощение ContentView

Заменить встроенные компоненты:

```swift
// БЫЛО:
private var headerView: some View {
    HStack {
        SearchBar(text: $appManager.searchText)
            .padding(.horizontal)
            .glassEffect(.regular.interactive())
        
        Spacer()
        
        HStack(spacing: 15) {
            settingsMenu  // 80+ строк кода меню
        }
    }
    .padding(.horizontal)
}

// СТАЛО:
private var headerView: some View {
    HeaderView(
        searchText: $appManager.searchText,
        showingFolderCreation: $showingFolderCreation,
        showingHiddenApps: $showingHiddenApps,
        showingAddCustomApp: $showingAddCustomApp,
        showingSettings: $showingSettings,
        showAllApps: $showAllApps,
        isLoading: appManager.isLoading,
        hiddenAppsCount: folderManager.hiddenAppPaths.count,
        onRefresh: {
            appManager.isLoading = true
            appManager.loadApplications()
        }
    )
}
```

```swift
// БЫЛО:
private var statisticsView: some View {
    HStack {
        Text("Папок: \(folderManager.folders.count) • Приложений: \(appManager.filteredApps.count) • Скрыто: \(folderManager.hiddenAppPaths.count)")
            .font(.caption)
            .foregroundColor(.secondary)
        
        Spacer()
    }
    .padding(.horizontal)
}

// СТАЛО:
private var statisticsView: some View {
    StatisticsView(
        foldersCount: folderManager.folders.count,
        appsCount: appManager.filteredApps.count,
        hiddenCount: folderManager.hiddenAppPaths.count
    )
}
```

```swift
// БЫЛО:
@ViewBuilder
private var dragOverlay: some View {
    if isDragTargeted {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(Color.accentColor, lineWidth: 3)
            // ... 20+ строк кода
    }
}

// СТАЛО:
private var dragOverlay: some View {
    DragDropOverlay(isTargeted: isDragTargeted)
}
```

Делегировать drag & drop:

```swift
// Добавить в ContentView:
private let dragDropHandler: DragDropHandler

init() {
    // В init или после создания appManager:
    dragDropHandler = DragDropHandler(appManager: appManager)
}

// БЫЛО: 100+ строк handleDrop
private func handleDrop(providers: [NSItemProvider]) -> Bool {
    // огромная логика
}

// СТАЛО:
private func handleDrop(providers: [NSItemProvider]) -> Bool {
    dragDropHandler.handleDrop(providers: providers) { successCount in
        if successCount > 0 {
            // показать уведомление
        }
    }
    return true
}
```

---

## 📊 Ожидаемый результат

### Размер файлов после рефакторинга:

| Файл | До | После |
|------|-----|--------|
| ContentView.swift | 534 строки | ~150 строк |
| ApplicationManager.swift | 140 строк | ~80 строк |
| FolderManager.swift | 240 строк | ~100 строк |

### Новые файлы:
- AppLaunchService.swift (45 строк)
- AppScannerService.swift (90 строк)
- StorageService.swift (170 строк)
- HeaderView.swift (95 строк)
- StatisticsView.swift (25 строк)
- DragDropOverlay.swift (40 строк)
- DragDropHandler.swift (130 строк)

**Общий выигрыш**: Код стал модульнее и понятнее!

---

## 🐛 Возможные проблемы и решения

### Проблема 1: "Cannot find 'AppInfo' in scope"
**Причина**: Файл не добавлен в Target  
**Решение**: Проверить Target Membership в File Inspector

### Проблема 2: "Use of unresolved identifier 'SearchBar'"
**Причина**: Circular dependency или не добавлен файл  
**Решение**: Убедиться что SearchBar.swift в том же Target

### Проблема 3: Приложение не компилируется после изменений
**Причина**: Изменили API, но старый код ещё вызывает  
**Решение**: Менять постепенно, по одному файлу

---

## ✅ Проверочный список

- [ ] Все новые файлы добавлены в Xcode
- [ ] У всех файлов стоит галочка Target: LaunchDock
- [ ] Проект собирается (⌘B)
- [ ] ApplicationManager использует AppScannerService
- [ ] ApplicationManager использует AppLaunchService
- [ ] FolderManager использует StorageService
- [ ] ContentView использует HeaderView
- [ ] ContentView использует StatisticsView
- [ ] ContentView использует DragDropOverlay
- [ ] ContentView использует DragDropHandler
- [ ] ContentView уменьшился до ~150 строк
- [ ] Все функции работают как раньше
- [ ] Нет warning'ов и ошибок

---

**Готово к интеграции!** 🚀
