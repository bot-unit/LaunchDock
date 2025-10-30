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
    @Published var sourceFilter: Set<AppInfo.AppSource> = Set(AppInfo.AppSource.allCases)
    
    var filteredApps: [AppInfo] {
        let visibleApps = folderManager?.getVisibleApps(applications) ?? applications
        var filtered = visibleApps
        
        // Фильтр по источнику
        filtered = filtered.filter { sourceFilter.contains($0.source) }
        
        // Фильтр по поиску
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
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
            apps.append(contentsOf: self.scanDirectory(applicationsURL, source: .applications))
            
            // Поиск системных приложений в /System/Applications
            let systemApplicationsURL = URL(fileURLWithPath: "/System/Applications")
            apps.append(contentsOf: self.scanDirectory(systemApplicationsURL, source: .systemApplications))
            
            // Поиск системных утилит в /System/Applications/Utilities
            let systemUtilitiesURL = URL(fileURLWithPath: "/System/Applications/Utilities")
            apps.append(contentsOf: self.scanDirectory(systemUtilitiesURL, source: .systemUtilities))
            
            // Поиск в папке пользователя Applications
            let userApplicationsURL = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications")
            apps.append(contentsOf: self.scanDirectory(userApplicationsURL, source: .userApplications))
            
            // Удаление дубликатов и сортировка
            let uniqueApps = Array(Set(apps))
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            
            DispatchQueue.main.async {
                self.applications = uniqueApps
                self.isLoading = false
            }
        }
    }
       
    private func scanDirectory(_ url: URL, source: AppInfo.AppSource) -> [AppInfo] {
        var apps: [AppInfo] = []
        
        guard FileManager.default.fileExists(atPath: url.path) else { return apps }
        
        if let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isApplicationKey, .localizedNameKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) {
            for case let appURL as URL in enumerator {
                if appURL.pathExtension == "app" {
                    if let appInfo = createAppInfo(from: appURL, source: source) {
                        apps.append(appInfo)
                    }
                }
            }
        }
        
        return apps
    }
    
    private func createAppInfo(from url: URL, source: AppInfo.AppSource) -> AppInfo? {
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
            path: url.path,
            source: source
        )
    }
    
    func launchApplication(_ app: AppInfo) {
        guard let appURL = URL(string: app.path) else { return }
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { (app, error) in
            if let error = error {
                print("Failed to launch application: \(error.localizedDescription)")
            }
        }
    }
}
