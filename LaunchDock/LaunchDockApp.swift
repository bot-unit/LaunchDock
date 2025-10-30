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
    //var body: some Scene { Settings {} }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .pasteboard) { }
            CommandGroup(replacing: .undoRedo) { }
        }
    }
}
