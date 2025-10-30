//
//  SettingsView.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-26.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var folderManager: FolderManager
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            Form {
                Toggle("Dark Mode", isOn: $settingsManager.isDarkMode)
                
                Slider(value: $settingsManager.numberOfColumns, in: 4...12, step: 1) {
                    Text("Number of Columns")
                }
                
                Slider(value: $settingsManager.iconSize, in: 32...128, step: 1) {
                    Text("Icon Size")
                }
                
                Slider(value: $settingsManager.fontSize, in: 8...16, step: 1) {
                    Text("Font Size")
                }
                
                Slider(value: $settingsManager.spacing, in: 10...40, step: 1) {
                    Text("Spacing")
                }
                
                Toggle("Show Application Names", isOn: $settingsManager.showAppNames)
                
                Button("Export Configuration") {
                    exportConfig()
                }
                
                Button("Import Configuration") {
                    importConfig()
                }
                
                Button("Reset Configuration") {
                    resetConfig()
                }
            }
            
            Section(header: Text("Configuration File")) {
                Text(folderManager.configFilePath)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
                Button("Show in Finder") {
                    showInFinder()
                }
            }
                      
                        
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func exportConfig() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "launchdock_config.json"
        
        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                _ = folderManager.exportConfig(to: url)
            }
        }
    }
    
    private func importConfig() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        
        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                _ = folderManager.importConfig(from: url)
            }
        }
    }

    private func showInFinder() {
        let url = URL(fileURLWithPath: folderManager.configFilePath)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    private func resetConfig() {
        let alert = NSAlert()
        alert.messageText = "Reset Configuration?"
        alert.informativeText = "Are you sure you want to reset all settings to their default values? This action cannot be undone."
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            folderManager.resetConfig()
        }
    }
}
