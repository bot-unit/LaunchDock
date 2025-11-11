//
//  ApplicationManager.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-03.
//

import SwiftUI
import Cocoa
import Foundation
import Combine

// MARK: - Application Manager
class ApplicationManager: ObservableObject {
    @Published var applications: [AppInfo] = []
    @Published var isLoading = true
    @Published var searchText = ""
    
    // MARK: - Services
    private let scanner = AppScannerService()
    private let launcher = AppLaunchService()
    private let storage = StorageService()

    // MARK: - Persistence
    private var customAppEntries: [StorageService.CustomAppEntry] = []
    
    // MARK: - Dependencies
    private var folderManager: FolderManager?
    
    // MARK: - Computed Properties
    var filteredApps: [AppInfo] {
        let visibleApps = folderManager?.getVisibleApps(applications) ?? applications
        if searchText.isEmpty {
            return visibleApps
        } else {
            return visibleApps.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        loadApplications()
    }
    
    // MARK: - Public Methods
    func setFolderManager(_ manager: FolderManager) {
        folderManager = manager
    }
    
    func loadApplications() {
        DispatchQueue.global(qos: .userInitiated).async {
            let scannedApps = self.scanner.scanAllApplications()

            DispatchQueue.main.async {
                self.applications = scannedApps
                // После загрузки системных приложений добавляем сохранённые пользовательские
                self.loadPersistedCustomApps()
                self.isLoading = false
            }
        }
    }
    
    func addCustomApplication(path: String) {
        let url = URL(fileURLWithPath: path)
        addCustomApplication(url: url)
    }

    func addCustomApplication(url: URL) {
        // Создаём security-scoped bookmark для последующих запусков
        var bookmarkData: Data? = nil
        do {
            bookmarkData = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
            // Не фатально: работаем без закладки, если не удалось создать
            bookmarkData = nil
        }

        let path = url.path
        if let appInfo = scanner.createAppInfo(from: url) {
            if !applications.contains(where: { $0.path == path }) {
                applications.append(appInfo)
                applications.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
            upsertCustomEntry(path: path, bookmark: bookmarkData)
            saveCustomAppEntries()
        }
    }
    
    func launchApplication(_ app: AppInfo) {
        launcher.launchApplication(app)
    }

    // MARK: - Custom Apps Persistence
    private func loadPersistedCustomApps() {
        do {
            let entries = try storage.loadCustomAppEntries()
            customAppEntries = entries

            var updated = false
            for entry in customAppEntries {
                let path = entry.path
                // Пропускаем уже загруженные
                guard !applications.contains(where: { $0.path == path }) else { continue }

                var resolvedURL: URL? = nil
                var needsNewBookmark = false

                if let bookmark = entry.bookmark {
                    var isStale = false
                    do {
                        let url = try URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
                        if url.startAccessingSecurityScopedResource() {
                            resolvedURL = url
                        } else {
                            resolvedURL = url // попробуем без скоупа
                        }
                        if isStale { needsNewBookmark = true }
                    } catch {
                        // Если не удалось, попробуем по пути
                        resolvedURL = URL(fileURLWithPath: path)
                    }
                } else {
                    resolvedURL = URL(fileURLWithPath: path)
                }

                guard let url = resolvedURL else { continue }
                defer {
                    if url.isFileURL { url.stopAccessingSecurityScopedResource() }
                }
                // Проверяем наличие файла
                guard FileManager.default.fileExists(atPath: url.path) else { continue }

                if let info = scanner.createAppInfo(from: url) {
                    applications.append(info)
                }
                if needsNewBookmark {
                    // Обновим устаревшую закладку
                    if let newBm = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
                        upsertCustomEntry(path: path, bookmark: newBm)
                        updated = true
                    }
                }
            }
            applications.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            // Чистим записи, которые больше не существуют
            let existing = customAppEntries.filter { FileManager.default.fileExists(atPath: $0.path) }
            if existing.count != customAppEntries.count {
                customAppEntries = existing
                updated = true
            }
            if updated {
                saveCustomAppEntries()
            }
        } catch {
            // Если не удалось загрузить, считаем список пустым
            customAppEntries = []
        }
    }

    private func upsertCustomEntry(path: String, bookmark: Data?) {
        if let idx = customAppEntries.firstIndex(where: { $0.path == path }) {
            let existing = customAppEntries[idx]
            customAppEntries[idx] = StorageService.CustomAppEntry(path: path, bookmark: bookmark ?? existing.bookmark)
        } else {
            customAppEntries.append(StorageService.CustomAppEntry(path: path, bookmark: bookmark))
        }
    }

    private func saveCustomAppEntries() {
        do {
            try storage.saveCustomAppEntries(customAppEntries)
        } catch {
            print("❌ Ошибка сохранения кастомных приложений: \(error)")
        }
    }
}
