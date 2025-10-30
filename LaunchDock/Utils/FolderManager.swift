//
//  FolderManager.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-03.
//

import Foundation
import Combine

// MARK: - Folder Manager
class FolderManager: ObservableObject {
    @Published var folders: [VirtualFolder] = []
    @Published var hiddenAppPaths: Set<String> = []
    
    private let configURL: URL
    private let hiddenAppsURL: URL
    
    init() {
        // Создаем папку для конфигурации в Documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let appConfigPath = documentsPath.appendingPathComponent("LaunchDockConfig")
        
        // Создаем папку, если её нет
        try? FileManager.default.createDirectory(at: appConfigPath, withIntermediateDirectories: true)
        
        configURL = appConfigPath.appendingPathComponent("folders.json")
        hiddenAppsURL = appConfigPath.appendingPathComponent("hidden-apps.json")
        
        loadFolders()
        loadHiddenApps()
    }
    
    // Получить путь к файлу конфигурации
    var configFilePath: String {
        return configURL.path
    }
    
    func addFolder(name: String, color: VirtualFolder.FolderColor) {
        let folder = VirtualFolder(name: name, appPaths: [], color: color)
        folders.append(folder)
        // print("✅ Создана новая папка: '\(name)' (цвет: \(color.rawValue))")
        // print("   ID: \(folder.id)")
        // print("   Всего папок: \(folders.count)")
        saveFolders()
    }
    
    func deleteFolder(_ folder: VirtualFolder) {
        folders.removeAll { $0.id == folder.id }
        saveFolders()
    }
    
    func updateFolder(_ folder: VirtualFolder) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index] = folder
            saveFolders()
        }
    }
    
    func addAppToFolder(_ app: AppInfo, folder: VirtualFolder) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            var updatedFolder = folders[index]
            updatedFolder.appPaths.insert(app.path)
            folders[index] = updatedFolder
            saveFolders()
            // print("✅ Добавлено приложение '\(app.name)' в папку '\(folder.name)'")
            // print("   Путь: \(app.path)")
            // print("   Всего приложений в папке: \(folders[index].appPaths.count)")
        } else {
            // print("❌ Папка не найдена: \(folder.name)")
        }
    }
    
    func removeAppFromFolder(_ app: AppInfo, folder: VirtualFolder) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            var updatedFolder = folders[index]
            updatedFolder.appPaths.remove(app.path)
            folders[index] = updatedFolder
            saveFolders()
            // print("✅ Удалено приложение '\(app.name)' из папки '\(folder.name)'")
        }
    }
    
    func getFolderForApp(_ app: AppInfo) -> VirtualFolder? {
        return folders.first { $0.appPaths.contains(app.path) }
    }
    
    func getAppsInFolder(_ folder: VirtualFolder, from allApps: [AppInfo]) -> [AppInfo] {
        let apps = allApps.filter { folder.appPaths.contains($0.path) }
        if apps.isEmpty && !folder.appPaths.isEmpty {
            // print("⚠️ В папке '\(folder.name)' нет видимых приложений, хотя путей: \(folder.appPaths.count)")
            // print("   Пути в папке: \(folder.appPaths)")
        }
        return apps
    }
    
    func getUnorganizedApps(_ allApps: [AppInfo]) -> [AppInfo] {
        let organizedPaths = Set(folders.flatMap { $0.appPaths })
        let unorganized = allApps.filter { !organizedPaths.contains($0.path) && !hiddenAppPaths.contains($0.path) }
        return unorganized
    }
    
    func getVisibleApps(_ allApps: [AppInfo]) -> [AppInfo] {
        return allApps.filter { !hiddenAppPaths.contains($0.path) }
    }
    
    func getHiddenApps(_ allApps: [AppInfo]) -> [AppInfo] {
        return allApps.filter { hiddenAppPaths.contains($0.path) }
    }
    
    func hideApp(_ app: AppInfo) {
        hiddenAppPaths.insert(app.path)
        // Также удаляем из всех папок при скрытии
        for i in 0..<folders.count {
            folders[i].appPaths.remove(app.path)
        }
        saveFolders()
        saveHiddenApps()
    }
    
    func showApp(_ app: AppInfo) {
        hiddenAppPaths.remove(app.path)
        saveHiddenApps()
    }
    
    func isAppHidden(_ app: AppInfo) -> Bool {
        return hiddenAppPaths.contains(app.path)
    }
    
    // Экспорт конфигурации в выбранное место
    func exportConfig(to url: URL) -> Bool {
        do {
            let config = [
                "folders": folders,
                "hiddenApps": Array(hiddenAppPaths)
            ] as [String : Any]
            
            let data = try JSONSerialization.data(withJSONObject: config, options: .prettyPrinted)
            try data.write(to: url)
            return true
        } catch {
            // print("Ошибка экспорта: \(error)")
            return false
        }
    }
    
    // Импорт конфигурации из файла
    func importConfig(from url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let foldersData = json?["folders"] as? Data {
                folders = try JSONDecoder().decode([VirtualFolder].self, from: foldersData)
            } else if let foldersArray = json?["folders"] as? [[String: Any]] {
                let foldersData = try JSONSerialization.data(withJSONObject: foldersArray)
                folders = try JSONDecoder().decode([VirtualFolder].self, from: foldersData)
            }
            
            if let hiddenAppsArray = json?["hiddenApps"] as? [String] {
                hiddenAppPaths = Set(hiddenAppsArray)
            }
            
            saveFolders()
            saveHiddenApps()
            return true
        } catch {
            // print("Ошибка импорта: \(error)")
            return false
        }
    }

    func resetConfig() {
        folders = []
        hiddenAppPaths = []
        saveFolders()
        saveHiddenApps()
    }
    
    private func saveFolders() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // Красивое форматирование
            let data = try encoder.encode(folders)
            try data.write(to: configURL)
            // print("✅ Папки сохранены в: \(configURL.path)")
            // print("   Количество папок: \(folders.count)")
            for folder in folders {
                // print("   - '\(folder.name)': \(folder.appPaths.count) приложений")
            }
        } catch {
            // print("❌ Ошибка сохранения папок: \(error)")
        }
    }
    
    private func loadFolders() {
        do {
            let data = try Data(contentsOf: configURL)
            let decoder = JSONDecoder()
            folders = try decoder.decode([VirtualFolder].self, from: data)
            // print("✅ Папки загружены из: \(configURL.path)")
            // print("   Загружено папок: \(folders.count)")
            for folder in folders {
                // print("   - '\(folder.name)' (ID: \(folder.id), приложений: \(folder.appPaths.count))")
            }
        } catch {
            // print("ℹ️ Файл конфигурации не найден, создаем новый: \(configURL.path)")
            folders = []
            saveFolders() // Создаем пустой файл
        }
    }
    
    private func saveHiddenApps() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(Array(hiddenAppPaths))
            try data.write(to: hiddenAppsURL)
            // print("✅ Скрытые приложения сохранены в: \(hiddenAppsURL.path)")
        } catch {
            // print("❌ Ошибка сохранения скрытых приложений: \(error)")
        }
    }
    
    private func loadHiddenApps() {
        do {
            let data = try Data(contentsOf: hiddenAppsURL)
            let decoder = JSONDecoder()
            let hiddenArray = try decoder.decode([String].self, from: data)
            hiddenAppPaths = Set(hiddenArray)
            // print("✅ Скрытые приложения загружены из: \(hiddenAppsURL.path)")
        } catch {
            // print("ℹ️ Файл скрытых приложений не найден, создаем новый: \(hiddenAppsURL.path)")
            hiddenAppPaths = []
            saveHiddenApps() // Создаем пустой файл
        }
    }
}

