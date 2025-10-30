//
//  SettingsManager.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-03.
//

import SwiftUI
import Foundation
import Combine

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    @Published var isDarkMode: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let darkModeKey = "isDarkMode"
    
    init() {
        isDarkMode = userDefaults.bool(forKey: darkModeKey)
        applyTheme()
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
        userDefaults.set(isDarkMode, forKey: darkModeKey)
        applyTheme()
    }
    
    private func applyTheme() {
        NSApp.appearance = isDarkMode ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
    }
}
