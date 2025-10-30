//
//  DragDropHandler.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-30.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Обработчик логики drag & drop для приложений
class DragDropHandler {
    
    // MARK: - Properties
    
    private weak var appManager: ApplicationManager?
    
    // MARK: - Initialization
    
    init(appManager: ApplicationManager? = nil) {
        self.appManager = appManager
    }
    
    // MARK: - Public Methods
    
    /// Обрабатывает событие drop
    /// - Parameters:
    ///   - providers: Провайдеры элементов
    ///   - completion: Callback с результатом
    func handleDrop(providers: [NSItemProvider], completion: @escaping (Int) -> Void) {
        guard !providers.isEmpty else {
            completion(0)
            return
        }
        
        var processedCount = 0
        var successCount = 0
        let totalCount = providers.count
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] (urlData, error) in
                    defer {
                        processedCount += 1
                        if processedCount == totalCount {
                            DispatchQueue.main.async {
                                completion(successCount)
                            }
                        }
                    }
                    
                    if let error = error {
                        print("Error loading dropped item: \(error.localizedDescription)")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        if let url = self?.extractURL(from: urlData) {
                            if self?.handleDroppedURL(url, silent: totalCount > 1) == true {
                                successCount += 1
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Извлекает URL из данных
    private func extractURL(from urlData: Any?) -> URL? {
        var finalURL: URL?
        
        // Способ 1: urlData как Data со строкой пути
        if let urlData = urlData as? Data,
           let urlString = String(data: urlData, encoding: .utf8) {
            let cleanedString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
            finalURL = URL(string: cleanedString) ?? URL(fileURLWithPath: cleanedString)
        }
        // Способ 2: urlData напрямую как URL
        else if let url = urlData as? URL {
            finalURL = url
        }
        // Способ 3: urlData как NSURL
        else if let nsurl = urlData as? NSURL {
            finalURL = nsurl as URL
        }
        
        return finalURL
    }
    
    /// Обрабатывает отдельный dropped URL
    @discardableResult
    private func handleDroppedURL(_ url: URL, silent: Bool = false) -> Bool {
        let path = url.path
        
        // Проверяем, что это приложение (.app)
        guard path.hasSuffix(".app") else {
            if !silent {
                print("Dropped file is not an application: \(path)")
            }
            return false
        }
        
        // Проверяем, что файл существует
        guard FileManager.default.fileExists(atPath: path) else {
            if !silent {
                print("Application file does not exist at path: \(path)")
            }
            return false
        }
        
        // Проверяем, не добавлено ли уже это приложение
        if appManager?.applications.contains(where: { $0.path == path }) == true {
            if !silent {
                print("Application already exists in the list: \(path)")
            }
            return false
        }
        
        // Добавляем приложение
        appManager?.addCustomApplication(path: path)
        
        if !silent {
            print("✅ Successfully added application from path: \(path)")
        }
        
        return true
    }
}
