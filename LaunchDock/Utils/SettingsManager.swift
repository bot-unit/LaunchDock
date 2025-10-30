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
    @Published var numberOfColumns: Double = 8.0
    @Published var iconSize: Double = 64.0
    @Published var fontSize: Double = 12.0
    @Published var spacing: Double = 20.0
    @Published var showAppNames: Bool = true
    
    private let userDefaults = UserDefaults.standard
    private let darkModeKey = "isDarkMode"
    private let numberOfColumnsKey = "numberOfColumns"
    private let iconSizeKey = "iconSize"
    private let fontSizeKey = "fontSize"
    private let spacingKey = "spacing"
    private let showAppNamesKey = "showAppNames"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        isDarkMode = userDefaults.bool(forKey: darkModeKey)
        numberOfColumns = userDefaults.double(forKey: numberOfColumnsKey)
        if numberOfColumns == 0 {
            numberOfColumns = 8.0
        }
        iconSize = userDefaults.double(forKey: iconSizeKey)
        if iconSize == 0 {
            iconSize = 64.0
        }
        fontSize = userDefaults.double(forKey: fontSizeKey)
        if fontSize == 0 {
            fontSize = 12.0
        }
        spacing = userDefaults.double(forKey: spacingKey)
        if spacing == 0 {
            spacing = 20.0
        }
        showAppNames = userDefaults.bool(forKey: showAppNamesKey)
        applyTheme()
        
        $numberOfColumns
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: self!.numberOfColumnsKey)
            }
            .store(in: &cancellables)
            
        $iconSize
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: self!.iconSizeKey)
            }
            .store(in: &cancellables)
            
        $fontSize
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: self!.fontSizeKey)
            }
            .store(in: &cancellables)
            
        $spacing
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: self!.spacingKey)
            }
            .store(in: &cancellables)
            
        $showAppNames
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: self!.showAppNamesKey)
            }
            .store(in: &cancellables)
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
