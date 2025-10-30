//
//  Bundle+Extensions.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-26.
//

import Foundation

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
    }
}
