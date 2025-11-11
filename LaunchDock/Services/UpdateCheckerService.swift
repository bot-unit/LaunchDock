//
//  UpdateCheckerService.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-30.
//

import Foundation
import AppKit

/// Информация об обновлении приложения
struct AppUpdate: Identifiable {
    let id: String
    let appName: String
    let bundleIdentifier: String
    let currentVersion: String
    let availableVersion: String?
    let updateAvailable: Bool
    let updateSource: UpdateSource
    
    enum UpdateSource: Equatable {
        case sparkle(feedURL: URL)
        case macAppStore
        case none
    }
}

/// Сервис для проверки обновлений приложений
class UpdateCheckerService {
    
    // MARK: - Public Methods
    
    /// Проверяет обновления для списка приложений
    /// - Parameter apps: Массив приложений для проверки
    /// - Returns: Массив информации об обновлениях
    func checkForUpdates(apps: [AppInfo]) async -> [AppUpdate] {
        var updates: [AppUpdate] = []
        
        // Фильтруем только приложения из /Applications
        let mainApps = apps.filter { $0.url.path.hasPrefix("/Applications/") }
        
        for app in mainApps {
            guard let bundle = Bundle(url: app.url),
                  let bundleIdentifier = bundle.bundleIdentifier else {
                continue
            }
            
            let currentVersion = extractVersion(from: bundle)
            let updateSource = detectUpdateSource(from: bundle)
            
            var availableVersion: String? = nil
            var updateAvailable = false
            
            // Проверяем обновления в зависимости от источника
            switch updateSource {
            case .sparkle(let feedURL):
                if let remoteVersion = await fetchSparkleVersion(from: feedURL) {
                    availableVersion = remoteVersion
                    updateAvailable = compareVersions(current: currentVersion, remote: remoteVersion)
                }
            case .macAppStore:
                // Для Mac App Store приложений можно проверить через iTunes Search API
                if let remoteVersion = await fetchMacAppStoreVersion(bundleIdentifier: bundleIdentifier) {
                    availableVersion = remoteVersion
                    updateAvailable = compareVersions(current: currentVersion, remote: remoteVersion)
                }
            case .none:
                break
            }
            
            let appUpdate = AppUpdate(
                id: app.id,
                appName: app.name,
                bundleIdentifier: bundleIdentifier,
                currentVersion: currentVersion,
                availableVersion: availableVersion,
                updateAvailable: updateAvailable,
                updateSource: updateSource
            )
            
            updates.append(appUpdate)
        }
        
        return updates
    }
    
    // MARK: - Private Methods
    
    /// Извлекает версию из Bundle
    private func extractVersion(from bundle: Bundle) -> String {
        if let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        if let buildVersion = bundle.infoDictionary?["CFBundleVersion"] as? String {
            return buildVersion
        }
        return "Unknown"
    }
    
    /// Определяет источник обновлений для приложения
    private func detectUpdateSource(from bundle: Bundle) -> AppUpdate.UpdateSource {
        // Проверяем Sparkle feed
        if let feedURL = extractSparkleFeedURL(from: bundle) {
            return .sparkle(feedURL: feedURL)
        }
        
        // Проверяем Mac App Store
        if isMacAppStoreApp(bundle: bundle) {
            return .macAppStore
        }
        
        return .none
    }
    
    /// Извлекает Sparkle feed URL из Bundle
    private func extractSparkleFeedURL(from bundle: Bundle) -> URL? {
        guard let information = bundle.infoDictionary else {
            return nil
        }
        
        // Стандартный Sparkle feed
        if let urlString = information["SUFeedURL"] as? String,
           let feedURL = URL(string: urlString.trimmingCharacters(in: CharacterSet(charactersIn: "'\""))) {
            return feedURL
        }
        
        // DevMate framework
        if let bundleIdentifier = bundle.bundleIdentifier,
           hasDevMateFramework(bundle: bundle) {
            var feedURL = URL(string: "https://updates.devmate.com")
            feedURL?.appendPathComponent(bundleIdentifier)
            feedURL?.appendPathExtension("xml")
            return feedURL
        }
        
        return nil
    }
    
    /// Проверяет наличие DevMate framework
    private func hasDevMateFramework(bundle: Bundle) -> Bool {
        let frameworksURL = URL(fileURLWithPath: bundle.bundlePath, isDirectory: true)
            .appendingPathComponent("Contents")
            .appendingPathComponent("Frameworks")
        
        guard let frameworks = try? FileManager.default.contentsOfDirectory(atPath: frameworksURL.path) else {
            return false
        }
        
        return frameworks.contains(where: { $0.contains("DevMateKit") })
    }
    
    /// Проверяет является ли приложение из Mac App Store
    private func isMacAppStoreApp(bundle: Bundle) -> Bool {
        let receiptURL = bundle.appStoreReceiptURL
        return receiptURL?.path.contains("_MASReceipt") ?? false
    }
    
    /// Получает версию из Sparkle feed
    private func fetchSparkleVersion(from feedURL: URL) async -> String? {
        do {
            let (data, response) = try await URLSession.shared.data(from: feedURL)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    return nil
                }
            }
            
            // Простой парсинг XML для получения версии
            if let xmlString = String(data: data, encoding: .utf8) {
                return parseSparkleVersion(from: xmlString)
            }
        } catch {
            // Игнорируем ошибки
        }
        return nil
    }
    
    /// Парсит версию из Sparkle XML
    private func parseSparkleVersion(from xml: String) -> String? {
        // Ищем sparkle:version или enclosure sparkle:shortVersionString
        let patterns = [
            #"sparkle:version=\"([^\"]+)\""#,
            #"sparkle:shortVersionString=\"([^\"]+)\""#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
               let range = Range(match.range(at: 1), in: xml) {
                return String(xml[range])
            }
        }
        
        return nil
    }
    
    /// Получает версию из Mac App Store через iTunes Search API
    private func fetchMacAppStoreVersion(bundleIdentifier: String) async -> String? {
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleIdentifier)") else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let firstResult = results.first,
               let version = firstResult["version"] as? String {
                return version
            }
        } catch {
            // Игнорируем ошибки
        }
        
        return nil
    }
    
    /// Сравнивает версии (простое сравнение строк)
    private func compareVersions(current: String, remote: String) -> Bool {
        // Убираем буквы и оставляем только цифры и точки
        let cleanCurrent = current.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: ".")
        let cleanRemote = remote.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: ".")
        
        let currentComponents = cleanCurrent.split(separator: ".").compactMap { Int($0) }
        let remoteComponents = cleanRemote.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(currentComponents.count, remoteComponents.count) {
            let currentPart = i < currentComponents.count ? currentComponents[i] : 0
            let remotePart = i < remoteComponents.count ? remoteComponents[i] : 0
            
            if remotePart > currentPart {
                return true
            } else if remotePart < currentPart {
                return false
            }
        }
        
        return false
    }
}
