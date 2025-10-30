//
//  AppScannerService.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-30.
//

import Foundation
import AppKit
import SwiftUI

/// Сервис для сканирования и поиска приложений в файловой системе
class AppScannerService {
    
    // MARK: - Properties
    
    /// Стандартные директории для поиска приложений
    private let standardDirectories: [URL] = [
        URL(fileURLWithPath: "/Applications"),
        URL(fileURLWithPath: "/System/Applications"),
        URL(fileURLWithPath: "/System/Applications/Utilities"),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
    ]
    
    // MARK: - Public Methods
    
    /// Сканирует все стандартные директории и возвращает найденные приложения
    /// - Returns: Массив уникальных приложений, отсортированный по имени
    func scanAllApplications() -> [AppInfo] {
        var apps: [AppInfo] = []
        
        for directory in standardDirectories {
            apps.append(contentsOf: scanDirectory(directory))
        }
        
        // Удаление дубликатов и сортировка
        let uniqueApps = Array(Set(apps))
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        
        return uniqueApps
    }
    
    /// Сканирует указанную директорию на наличие приложений
    /// - Parameter url: URL директории для сканирования
    /// - Returns: Массив найденных приложений
    func scanDirectory(_ url: URL) -> [AppInfo] {
        var apps: [AppInfo] = []
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return apps
        }
        
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isApplicationKey, .localizedNameKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return apps
        }
        
        for case let appURL as URL in enumerator {
            if appURL.pathExtension == "app" {
                if let appInfo = createAppInfo(from: appURL) {
                    apps.append(appInfo)
                }
            }
        }
        
        return apps
    }
    
    /// Создаёт AppInfo из URL приложения
    /// - Parameter url: URL файла приложения (.app)
    /// - Returns: AppInfo или nil, если не удалось создать
    func createAppInfo(from url: URL) -> AppInfo? {
        guard let bundle = Bundle(url: url) else {
            return nil
        }
        
        let appName = extractAppName(from: bundle, url: url)
        let bundleIdentifier = bundle.bundleIdentifier
        
        return AppInfo(
            name: appName,
            bundleIdentifier: bundleIdentifier,
            url: url
        )
    }
    
    // MARK: - Private Methods
    
    /// Извлекает имя приложения из Bundle или URL
    private func extractAppName(from bundle: Bundle, url: URL) -> String {
        return bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String ??
               bundle.infoDictionary?["CFBundleDisplayName"] as? String ??
               bundle.localizedInfoDictionary?["CFBundleName"] as? String ??
               bundle.infoDictionary?["CFBundleName"] as? String ??
               url.deletingPathExtension().lastPathComponent
    }
}
