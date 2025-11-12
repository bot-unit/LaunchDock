//
//  LaunchDockApp.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-09-22.
//

import SwiftUI
import Cocoa
import Foundation

@main
struct LaunchpadApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, maxWidth: 900, minHeight: 700, maxHeight: 700)
        }
        // Оставляем управление окном через AppDelegate (без явного hiddenTitleBar стиля)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .pasteboard) { }
            CommandGroup(replacing: .undoRedo) { }
        }
    }
}
