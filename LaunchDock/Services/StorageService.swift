//
//  StorageService.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-30.
//

import Foundation

/// Универсальный сервис для работы с хранением данных в формате JSON
class StorageService {
    
    // MARK: - Properties
    
    private let configDirectoryURL: URL
    
    // MARK: - Initialization
    
    init() {
        // Создаём директорию для конфигурации в Documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.configDirectoryURL = documentsPath.appendingPathComponent("LaunchDockConfig")
        
        // Создаём папку, если её нет
        try? FileManager.default.createDirectory(
            at: configDirectoryURL,
            withIntermediateDirectories: true
        )
    }
    
    // MARK: - Generic Methods
    
    /// Сохраняет данные в JSON файл
    /// - Parameters:
    ///   - data: Данные для сохранения (должны соответствовать Encodable)
    ///   - filename: Имя файла (например, "folders.json")
    /// - Throws: Ошибка кодирования или записи
    func save<T: Encodable>(_ data: T, to filename: String) throws {
        let fileURL = configDirectoryURL.appendingPathComponent(filename)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: fileURL)
    }
    
    /// Загружает данные из JSON файла
    /// - Parameters:
    ///   - type: Тип данных для декодирования
    ///   - filename: Имя файла (например, "folders.json")
    /// - Returns: Декодированные данные или nil, если файл не существует
    /// - Throws: Ошибка декодирования
    func load<T: Decodable>(_ type: T.Type, from filename: String) throws -> T? {
        let fileURL = configDirectoryURL.appendingPathComponent(filename)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
    
    /// Удаляет файл с данными
    /// - Parameter filename: Имя файла для удаления
    /// - Throws: Ошибка удаления файла
    func delete(filename: String) throws {
        let fileURL = configDirectoryURL.appendingPathComponent(filename)
        try FileManager.default.removeItem(at: fileURL)
    }
    
    /// Проверяет существование файла
    /// - Parameter filename: Имя файла
    /// - Returns: true, если файл существует
    func fileExists(filename: String) -> Bool {
        let fileURL = configDirectoryURL.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    /// Получает URL файла конфигурации
    /// - Parameter filename: Имя файла
    /// - Returns: Полный URL файла
    func fileURL(for filename: String) -> URL {
        return configDirectoryURL.appendingPathComponent(filename)
    }
    
    // MARK: - Specialized Methods for App Config
    
    /// Сохраняет папки
    func saveFolders(_ folders: [VirtualFolder]) throws {
        try save(folders, to: "folders.json")
    }
    
    /// Загружает папки
    func loadFolders() throws -> [VirtualFolder] {
        return try load([VirtualFolder].self, from: "folders.json") ?? []
    }
    
    /// Сохраняет скрытые приложения
    func saveHiddenApps(_ hiddenAppPaths: Set<String>) throws {
        try save(Array(hiddenAppPaths), to: "hidden-apps.json")
    }
    
    /// Загружает скрытые приложения
    func loadHiddenApps() throws -> Set<String> {
        let array = try load([String].self, from: "hidden-apps.json") ?? []
        return Set(array)
    }

    // MARK: - Custom Apps Entries with Security-Scoped Bookmarks

    /// Запись о кастомном приложении с возможной security-скоуп закладкой
    struct CustomAppEntry: Codable, Equatable {
        let path: String
        let bookmark: Data?
    }

    /// Сохраняет записи кастомных приложений (с закладками)
    func saveCustomAppEntries(_ entries: [CustomAppEntry]) throws {
        try save(entries, to: "custom-apps.json")
    }

    /// Загружает записи кастомных приложений (с поддержкой старого формата)
    func loadCustomAppEntries() throws -> [CustomAppEntry] {
        // Пробуем новый формат
        if let entries = try load([CustomAppEntry].self, from: "custom-apps.json") {
            return entries
        }
        // Фолбэк на старый формат: массив строк-путей
        if let paths = try load([String].self, from: "custom-apps.json") {
            return paths.map { CustomAppEntry(path: $0, bookmark: nil) }
        }
        return []
    }

    // MARK: - Custom (Manually Added) Applications

    /// Сохраняет список вручную добавленных приложений
    /// - Parameter customAppPaths: Массив путей к приложениям (.app)
    func saveCustomApps(_ customAppPaths: [String]) throws {
        try save(customAppPaths, to: "custom-apps.json")
    }

    /// Загружает список вручную добавленных приложений
    /// - Returns: Массив путей или пустой массив, если файл отсутствует
    func loadCustomApps() throws -> [String] {
        return try load([String].self, from: "custom-apps.json") ?? []
    }
    
    /// Экспортирует конфигурацию в указанное место
    /// - Parameters:
    ///   - folders: Папки для экспорта
    ///   - hiddenAppPaths: Скрытые приложения
    ///   - url: URL для сохранения
    /// - Returns: true в случае успеха
    func exportConfig(folders: [VirtualFolder], hiddenAppPaths: Set<String>, customAppPaths: Set<String> = [], to url: URL) -> Bool {
        do {
            let config: [String: Any] = [
                "folders": try JSONEncoder().encode(folders),
                "hiddenApps": Array(hiddenAppPaths),
                "customApps": Array(customAppPaths)
            ]
            
            let data = try JSONSerialization.data(withJSONObject: config, options: .prettyPrinted)
            try data.write(to: url)
            return true
        } catch {
            print("Ошибка экспорта: \(error)")
            return false
        }
    }
    
    /// Импортирует конфигурацию из файла
    /// - Parameter url: URL файла для импорта
    /// - Returns: Кортеж с папками и скрытыми приложениями, или nil при ошибке
    func importConfig(from url: URL) -> (folders: [VirtualFolder], hiddenApps: Set<String>, customApps: Set<String>)? {
        do {
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }
            
            var folders: [VirtualFolder] = []
            var hiddenApps: Set<String> = []
            var customApps: Set<String> = []
            
            // Загружаем папки
            if let foldersData = json["folders"] as? Data {
                folders = try JSONDecoder().decode([VirtualFolder].self, from: foldersData)
            } else if let foldersArray = json["folders"] as? [[String: Any]] {
                let foldersData = try JSONSerialization.data(withJSONObject: foldersArray)
                folders = try JSONDecoder().decode([VirtualFolder].self, from: foldersData)
            }
            
            // Загружаем скрытые приложения
            if let hiddenAppsArray = json["hiddenApps"] as? [String] {
                hiddenApps = Set(hiddenAppsArray)
            }

            // Загружаем вручную добавленные приложения
            if let customAppsArray = json["customApps"] as? [String] {
                customApps = Set(customAppsArray)
            }

            return (folders, hiddenApps, customApps)
        } catch {
            print("Ошибка импорта: \(error)")
            return nil
        }
    }
}
