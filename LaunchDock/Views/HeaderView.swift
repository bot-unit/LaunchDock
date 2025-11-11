//
//  HeaderView.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-30.
//

import SwiftUI

/// Компонент для отображения заголовка с поиском и настройками
struct HeaderView: View {
    @Binding var searchText: String
    @Binding var showingFolderCreation: Bool
    @Binding var showingHiddenApps: Bool
    @Binding var showingAddCustomApp: Bool
    @Binding var showingSettings: Bool
    @Binding var showAllApps: Bool
    @Binding var showingUpdatesCheck: Bool
    
    let isLoading: Bool
    let hiddenAppsCount: Int
    let onRefresh: () -> Void
    
    var body: some View {
        HStack {
            SearchBar(text: $searchText)
                .padding(.horizontal)
                .glassEffect(.regular.interactive())
            
            Spacer()
            
            HStack(spacing: 15) {
                settingsMenu
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Settings Menu
    private var settingsMenu: some View {
        Menu {
            Button("Новая папка") {
                showingFolderCreation = true
            }
            
            Button("Обновить приложения") {
                onRefresh()
            }
            .disabled(isLoading)
            
            Button("Проверить обновления...") {
                showingUpdatesCheck = true
            }
            
            Divider()
            
            Menu("Режим отображения") {
                Button(action: { showAllApps = false }) {
                    HStack {
                        Text("Только неорганизованные")
                        if !showAllApps {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button(action: { showAllApps = true }) {
                    HStack {
                        Text("Все приложения")
                        if showAllApps {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            Divider()
            
            Button("Скрытые приложения (\(hiddenAppsCount))") {
                showingHiddenApps = true
            }
            
            Button("Добавить приложение вручную...") {
                showingAddCustomApp = true
            }
            
            Divider()
            
            Button("Settings") {
                showingSettings = true
            }
        } label: {
            Image(systemName: "gear")
                .font(.title2)
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .help("Настройки и управление")
    }
}
