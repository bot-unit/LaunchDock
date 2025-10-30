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
            let apps = self.scanner.scanAllApplications()
            
            DispatchQueue.main.async {
                self.applications = apps
                self.isLoading = false
            }
        }
    }
    
    func addCustomApplication(path: String) {
        let url = URL(fileURLWithPath: path)
        
        if let appInfo = scanner.createAppInfo(from: url) {
            // Проверяем, нет ли уже такого приложения
            if !applications.contains(where: { $0.path == path }) {
                applications.append(appInfo)
                applications.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
        }
    }
    
    func launchApplication(_ app: AppInfo) {
        launcher.launchApplication(app)
    }
}
