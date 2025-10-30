//
//  AppInfo.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-03.
//

import SwiftUI
import Foundation

struct AppInfo: Identifiable, Equatable, Hashable {
    var id: String { url.path }
    let name: String
    let bundleIdentifier: String?
    let url: URL
    var path: String { url.path }
    var icon: NSImage { NSWorkspace.shared.icon(forFile: url.path) }
        
    func hash(into hasher: inout Hasher) {
        hasher.combine(url.path)
    }
    
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.url == rhs.url
    }
}
