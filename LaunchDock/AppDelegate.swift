//
//  AppDelegate.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-06.
//

import SwiftUI
import Cocoa
import Foundation

extension Notification.Name {
    static let launchpadWindowShown = Notification.Name("LaunchDockWindowShown")
    static let launchpadWindowHidden = Notification.Name("LaunchDockWindowHidden")
}

class BorderlessWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let window = NSApplication.shared.windows.first {
            window.setFrameAutosaveName("LaunchDockWindow")
            window.center()
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

