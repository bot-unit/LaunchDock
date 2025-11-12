//
//  AppDelegate.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-06.
//

import SwiftUI
import Cocoa
import Foundation

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let window = NSApplication.shared.windows.first {
            // Сохранение позиции
            window.setFrameAutosaveName("LaunchDockWindow")
            window.center()
            
            // Прозрачный заголовок и скрытие текста
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            
            // Скрываем стандартные кнопки (traffic lights)
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            
            // Разрешаем перетаскивание за любую область фонового контента
            window.isMovableByWindowBackground = true

            // Запрет изменения размера окна
            window.styleMask.remove(.resizable)
            window.minSize = NSSize(width: 900, height: 700)
            window.maxSize = NSSize(width: 900, height: 700)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Здесь можно вставить очистку ресурсов / сохранение состояния, если потребуется.
        // Так как длительных операций нет – завершаемся сразу.
        return .terminateNow
    }
}

