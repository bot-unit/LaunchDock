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
    
    private var folderManager: FolderManager?
    
    func setFolderManager(_ manager: FolderManager) {
        folderManager = manager
    }
    
    init() {
        loadApplications()
    }
    
    func loadApplications() {
        DispatchQueue.global(qos: .userInitiated).async {
            var apps: [AppInfo] = []
            
            // Поиск приложений в /Applications
            let applicationsURL = URL(fileURLWithPath: "/Applications")
            apps.append(contentsOf: self.scanDirectory(applicationsURL))
            
            // Поиск системных приложений в /System/Applications
            let systemApplicationsURL = URL(fileURLWithPath: "/System/Applications")
            apps.append(contentsOf: self.scanDirectory(systemApplicationsURL))
            
            // Поиск системных утилит в /System/Applications/Utilities
            let systemUtilitiesURL = URL(fileURLWithPath: "/System/Applications/Utilities")
            apps.append(contentsOf: self.scanDirectory(systemUtilitiesURL))
            
            // Поиск в папке пользователя Applications
            let userApplicationsURL = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications")
            apps.append(contentsOf: self.scanDirectory(userApplicationsURL))
            
            // Удаление дубликатов и сортировка
            let uniqueApps = Array(Set(apps))
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            
            DispatchQueue.main.async {
                self.applications = uniqueApps
                self.isLoading = false
            }
        }
    }
    
    func addCustomApplication(path: String) {
        if let appInfo = createAppInfo(from: URL(fileURLWithPath: path)) {
            // Проверяем, нет ли уже такого приложения
            if !applications.contains(where: { $0.path == path }) {
                applications.append(appInfo)
                applications.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
        }
    }
    
    private func scanDirectory(_ url: URL) -> [AppInfo] {
        var apps: [AppInfo] = []
        
        guard FileManager.default.fileExists(atPath: url.path) else { return apps }
        
        if let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isApplicationKey, .localizedNameKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) {
            for case let appURL as URL in enumerator {
                if appURL.pathExtension == "app" {
                    if let appInfo = createAppInfo(from: appURL) {
                        apps.append(appInfo)
                    }
                }
            }
        }
        
        return apps
    }
    
    private func createAppInfo(from url: URL) -> AppInfo? {
        guard let bundle = Bundle(url: url) else { return nil }
        
        let appName = bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String ??
                      bundle.infoDictionary?["CFBundleDisplayName"] as? String ??
                      bundle.localizedInfoDictionary?["CFBundleName"] as? String ??
                      bundle.infoDictionary?["CFBundleName"] as? String ??
                      url.deletingPathExtension().lastPathComponent
        
        let bundleIdentifier = bundle.bundleIdentifier
        
        return AppInfo(
            name: appName,
            bundleIdentifier: bundleIdentifier,
            url: url,
        )
    }
    
    func launchApplication(_ app: AppInfo) {
        let appURL = app.url
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { (app, error) in
            if let error = error {
                print("Failed to launch application: \(error.localizedDescription)")
            }
        }
    }
}
