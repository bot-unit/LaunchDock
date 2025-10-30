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
    
    // MARK: - Services
    private let storage = StorageService()
    
    // MARK: - Initialization
    init() {
        loadFolders()
        loadHiddenApps()
    }
    
    // MARK: - Public Properties
    var configFilePath: String {
        return storage.fileURL(for: "folders.json").path
    }
    
    // MARK: - Folder Management
    func addFolder(name: String, color: VirtualFolder.FolderColor) {
        let folder = VirtualFolder(name: name, appPaths: [], color: color)
        folders.append(folder)
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
        }
    }
    
    func removeAppFromFolder(_ app: AppInfo, folder: VirtualFolder) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            var updatedFolder = folders[index]
            updatedFolder.appPaths.remove(app.path)
            folders[index] = updatedFolder
            saveFolders()
        }
    }
    
    func getFolderForApp(_ app: AppInfo) -> VirtualFolder? {
        return folders.first { $0.appPaths.contains(app.path) }
    }
    
    func getAppsInFolder(_ folder: VirtualFolder, from allApps: [AppInfo]) -> [AppInfo] {
        return allApps.filter { folder.appPaths.contains($0.path) }
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
    
    // MARK: - Import/Export
    func exportConfig(to url: URL) -> Bool {
        return storage.exportConfig(folders: folders, hiddenAppPaths: hiddenAppPaths, to: url)
    }
    
    func importConfig(from url: URL) -> Bool {
        guard let config = storage.importConfig(from: url) else {
            return false
        }
        
        folders = config.folders
        hiddenAppPaths = config.hiddenApps
        
        saveFolders()
        saveHiddenApps()
        return true
    }

    func resetConfig() {
        folders = []
        hiddenAppPaths = []
        saveFolders()
        saveHiddenApps()
    }
    
    // MARK: - Private Methods
    private func saveFolders() {
        do {
            try storage.saveFolders(folders)
        } catch {
            print("❌ Ошибка сохранения папок: \(error)")
        }
    }
    
    private func loadFolders() {
        do {
            folders = try storage.loadFolders()
        } catch {
            folders = []
            saveFolders()
        }
    }
    
    private func saveHiddenApps() {
        do {
            try storage.saveHiddenApps(hiddenAppPaths)
        } catch {
            print("❌ Ошибка сохранения скрытых приложений: \(error)")
        }
    }
    
    private func loadHiddenApps() {
        do {
            hiddenAppPaths = try storage.loadHiddenApps()
        } catch {
            hiddenAppPaths = []
            saveHiddenApps()
        }
    }
}
