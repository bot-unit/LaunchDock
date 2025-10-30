//
//  ContentView.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-09-22.
//

import SwiftUI
import Combine

// Main Content View
struct ContentView: View {
    @StateObject private var appManager = ApplicationManager()
    @StateObject private var folderManager = FolderManager()
    @StateObject private var settingsManager = SettingsManager()
    
    @State private var showingFolderCreation = false
    @State private var showingFolderContent = false
    @State private var showingHiddenApps = false
    @State private var showingAddCustomApp = false
    @State private var selectedFolder: VirtualFolder?
    @State private var showingAddToFolder = false
    @State private var selectedApp: AppInfo?
    @State private var showAllApps = false // Показывать все приложения или только неорганизованные
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 8)
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Custom Launchpad")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 15) {
                    Button(action: {
                        settingsManager.toggleTheme()
                    }) {
                        Image(systemName: settingsManager.isDarkMode ? "sun.max.fill" : "moon.fill")
                            .font(.title2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Переключить тему")
                    
                    Menu {
                        Button("Новая папка") {
                            showingFolderCreation = true
                        }
                        
                        Button("Обновить приложения") {
                            appManager.isLoading = true
                            appManager.loadApplications()
                        }
                        .disabled(appManager.isLoading)
                        
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
                        
                        Menu("Фильтр по источнику") {
                            ForEach(AppInfo.AppSource.allCases, id: \.self) { source in
                                Button(action: {
                                    if appManager.sourceFilter.contains(source) {
                                        appManager.sourceFilter.remove(source)
                                    } else {
                                        appManager.sourceFilter.insert(source)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: source.icon)
                                        Text(source.displayName)
                                        Spacer()
                                        if appManager.sourceFilter.contains(source) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                            
                            Button("Выбрать все") {
                                appManager.sourceFilter = Set(AppInfo.AppSource.allCases)
                            }
                            
                            Button("Снять все") {
                                appManager.sourceFilter.removeAll()
                            }
                        }
                        
                        Divider()
                        
                        Button("Скрытые приложения (\(folderManager.hiddenAppPaths.count))") {
                            showingHiddenApps = true
                        }
                        
                        Button("Добавить приложение вручную...") {
                            showingAddCustomApp = true
                        }
                        
                        Divider()
                        
                        Button("Экспорт конфигурации...") {
                            exportConfig()
                        }
                        
                        Button("Импорт конфигурации...") {
                            importConfig()
                        }
                        
                        Divider()
                        
                        Button("Показать файл конфигурации") {
                            showConfigFile()
                        }
                        
                        Button("Путь к конфигурации") {
                            copyConfigPath()
                        }
                    } label: {
                        Image(systemName: "gear")
                            .font(.title2)
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                    .help("Настройки и управление")
                }
            }
            .padding(.horizontal)
            
            // Search
            SearchBar(text: $appManager.searchText)
                .padding(.horizontal)
            
            // Content
            if appManager.isLoading {
                VStack {
                    ProgressView("Загрузка приложений...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        // Папки
                        ForEach(folderManager.folders) { folder in
                            let appsInFolder = folderManager.getAppsInFolder(folder, from: appManager.filteredApps)
                            
                            FolderView(
                                folder: folder,
                                apps: appsInFolder,
                                onOpenFolder: {
                                    selectedFolder = folder
                                    showingFolderContent = true
                                },
                                onEditFolder: {
                                    // TODO: Implement folder editing
                                },
                                onAppDropped: { appPath in
                                    // Найти приложение по пути
                                    if let app = appManager.applications.first(where: { $0.path == appPath }) {
                                        folderManager.addAppToFolder(app, folder: folder)
                                    }
                                }
                            )
                        }
                        
                        // Приложения (в зависимости от режима)
                        let appsToShow = showAllApps
                            ? folderManager.getVisibleApps(appManager.filteredApps)
                            : folderManager.getUnorganizedApps(appManager.filteredApps)
                        
                        ForEach(appsToShow) { app in
                            let folderForApp = folderManager.getFolderForApp(app)
                            
                            AppIconView(app: app) {
                                appManager.launchApplication(app)
                            } onAddToFolder: {
                                selectedApp = app
                                showingAddToFolder = true
                            } onHideApp: {
                                folderManager.hideApp(app)
                            }
                            .contextMenu {
                                Button("Добавить в папку...") {
                                    selectedApp = app
                                    showingAddToFolder = true
                                }
                                
                                if let folder = folderForApp {
                                    Button("Убрать из папки '\(folder.name)'") {
                                        folderManager.removeAppFromFolder(app, folder: folder)
                                    }
                                }
                                
                                Button("Скрыть приложение") {
                                    folderManager.hideApp(app)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            
            // Statistics
            HStack {
                let sourceStats = Dictionary(grouping: appManager.applications) { $0.source }
                    .mapValues { $0.count }
                
                Text("Папок: \(folderManager.folders.count) • Приложений: \(appManager.filteredApps.count) из \(appManager.applications.count) • Скрыто: \(folderManager.hiddenAppPaths.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Краткая статистика по источникам
                HStack(spacing: 8) {
                    ForEach(AppInfo.AppSource.allCases, id: \.self) { source in
                        if let count = sourceStats[source], count > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: source.icon)
                                    .font(.caption)
                                Text("\(count)")
                                    .font(.caption)
                            }
                            .foregroundColor(appManager.sourceFilter.contains(source) ? .primary : .secondary)
                            .opacity(appManager.sourceFilter.contains(source) ? 1.0 : 0.5)
                            .help(source.displayName)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            appManager.setFolderManager(folderManager)
        }
        .sheet(isPresented: $showingFolderCreation) {
            FolderCreationSheet(isPresented: $showingFolderCreation) { name, color in
                folderManager.addFolder(name: name, color: color)
            }
        }
        .sheet(isPresented: $showingFolderContent) {
            if let folder = selectedFolder {
                let appsInFolder = folderManager.getAppsInFolder(folder, from: appManager.applications)
                FolderAppsView(
                    folder: folder,
                    apps: appsInFolder,
                    isPresented: $showingFolderContent
                ) { app in
                    appManager.launchApplication(app)
                } onRemoveApp: { app in
                    folderManager.removeAppFromFolder(app, folder: folder)
                }
            }
        }
        .sheet(isPresented: $showingAddToFolder) {
            if let app = selectedApp {
                AddToFolderSheet(
                    app: app,
                    folders: folderManager.folders,
                    isPresented: $showingAddToFolder
                ) { folder in
                    folderManager.addAppToFolder(app, folder: folder)
                }
            }
        }
        .sheet(isPresented: $showingHiddenApps) {
            HiddenAppsView(
                hiddenApps: folderManager.getHiddenApps(appManager.applications),
                isPresented: $showingHiddenApps,
                onShowApp: { app in
                    folderManager.showApp(app)
                },
                onLaunchApp: { app in
                    appManager.launchApplication(app)
                }
            )
        }
    }
}
