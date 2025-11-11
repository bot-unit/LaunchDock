# Models

## AppInfo

```swift
struct AppInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleIdentifier: String?
    let url: URL
}
```

- `id`: stable across sessions (often derived from path or bundle id)
- `url`: absolute URL to `.app`

## VirtualFolder

```swift
struct VirtualFolder: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var appPaths: Set<String>
    var color: FolderColor
}
```

- `appPaths`: absolute paths to apps in the folder

## StorageService.CustomAppEntry

```swift
struct CustomAppEntry: Codable, Equatable {
    let path: String
    let bookmark: Data?
}
```

- `bookmark`: security-scoped bookmark for persistent sandboxed access
