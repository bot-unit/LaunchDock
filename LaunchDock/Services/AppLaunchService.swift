//
//  AppLaunchService.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-30.
//

import Foundation
import AppKit

/// Сервис для запуска приложений
class AppLaunchService {
    
    /// Запускает приложение
    /// - Parameter app: Информация о приложении для запуска
    /// - Returns: Успешно ли запущено приложение
    @discardableResult
    func launchApplication(_ app: AppInfo) -> Bool {
        let configuration = NSWorkspace.OpenConfiguration()
        var success = false
        
        NSWorkspace.shared.openApplication(at: app.url, configuration: configuration) { (app, error) in
            if let error = error {
                print("Failed to launch application: \(error.localizedDescription)")
                success = false
            } else {
                success = true
            }
        }
        
        return success
    }
    
    /// Запускает приложение асинхронно с callback
    /// - Parameters:
    ///   - app: Информация о приложении
    ///   - completion: Callback с результатом запуска
    func launchApplication(_ app: AppInfo, completion: @escaping (Result<Void, Error>) -> Void) {
        let configuration = NSWorkspace.OpenConfiguration()
        
        NSWorkspace.shared.openApplication(at: app.url, configuration: configuration) { (_, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
