//
//  ContentView.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-09-22.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

// Main Content View
struct ContentView: View {
    @StateObject private var appManager = ApplicationManager()
    @StateObject private var folderManager = FolderManager()
    @StateObject private var settingsManager = SettingsManager()
    
    @State private var showingFolderCreation = false
    @State private var showingHiddenApps = false
    @State private var showingAddCustomApp = false
    @State private var selectedFolder: VirtualFolder? // Используется для .sheet(item:)
    @State private var folderToEdit: VirtualFolder? // Используется для редактирования
    @State private var selectedApp: AppInfo? // Используется для .sheet(item:)
    @State private var showAllApps = false // Показывать все приложения или только неорганизованные
    @State private var showingSettings = false
    @State private var isLaunchingDisabled = false
    @State private var launchingAppId: String? = nil
    @State private var isDragTargeted = false
    
    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: settingsManager.spacing), count: Int(settingsManager.numberOfColumns))
    }
    
    var body: some View {
        mainContent
            .sheet(isPresented: $showingFolderCreation) {
                FolderCreationSheet(isPresented: $showingFolderCreation) { name, color in
                    // print("🔵 ContentView: Создание папки '\(name)' с цветом \(color.rawValue)")
                    folderManager.addFolder(name: name, color: color)
                }
            }
            .sheet(item: $selectedFolder) { folder in
                let appsInFolder = folderManager.getAppsInFolder(folder, from: appManager.applications)
                
                FolderAppsView(
                    folder: folder,
                    apps: appsInFolder,
                    iconSize: settingsManager.iconSize,
                    fontSize: settingsManager.fontSize,
                    spacing: settingsManager.spacing,
                    showAppNames: settingsManager.showAppNames,
                    isPresented: Binding(
                        get: { self.selectedFolder != nil },
                        set: { newValue in
                            if !newValue {
                                self.selectedFolder = nil
                            }
                        }
                    )
                ) { app in
                    if !isLaunchingDisabled {
                        isLaunchingDisabled = true
                        appManager.launchApplication(app)
                        appManager.searchText = ""
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            isLaunchingDisabled = false
                        }
                    }
                } onRemoveApp: { app in
                    folderManager.removeAppFromFolder(app, folder: folder)
                } onHideApp: { app in
                    folderManager.hideApp(app)
                }
            }
            .sheet(item: $selectedApp) { app in
                AddToFolderSheet(
                    app: app,
                    folderManager: folderManager,
                    isPresented: Binding(
                        get: { self.selectedApp != nil },
                        set: { newValue in
                            if !newValue {
                                self.selectedApp = nil
                            }
                        }
                    )
                ) { folder in
                    folderManager.addAppToFolder(app, folder: folder)
                    selectedApp = nil
                }
            }
            .sheet(isPresented: $showingHiddenApps) {
                HiddenAppsView(
                    hiddenApps: folderManager.getHiddenApps(appManager.applications),
                    iconSize: settingsManager.iconSize,
                    fontSize: settingsManager.fontSize,
                    spacing: settingsManager.spacing,
                    showAppNames: settingsManager.showAppNames,
                    isPresented: $showingHiddenApps,
                    onShowApp: { app in
                        folderManager.showApp(app)
                    },
                    onLaunchApp: { app in
                        if !isLaunchingDisabled {
                            isLaunchingDisabled = true
                            appManager.launchApplication(app)
                            appManager.searchText = ""
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                isLaunchingDisabled = false
                            }
                        }
                    }
                )
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(isPresented: $showingSettings, settingsManager: settingsManager, folderManager: folderManager)
            }
            .sheet(item: $folderToEdit) { folder in
                FolderEditSheet(isPresented: Binding(
                    get: { self.folderToEdit != nil },
                    set: { if !$0 { self.folderToEdit = nil } }
                ), folder: Binding(
                    get: { folder },
                    set: { self.folderToEdit = $0 }
                )) { updatedFolder in
                    folderManager.updateFolder(updatedFolder)
                }
            }
            .sheet(isPresented: $showingAddCustomApp) {
                AddCustomAppSheet(isPresented: $showingAddCustomApp) { path in
                    appManager.addCustomApplication(path: path)
                }
            }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 20) {
            headerView
            contentView
            statisticsView
        }
        .padding()
        .background(.ultraThinMaterial)
        .overlay(dragOverlay)
        .onDrop(of: [.fileURL], isTargeted: $isDragTargeted) { providers in
            handleDrop(providers: providers)
        }
        .onAppear {
            appManager.setFolderManager(folderManager)
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HeaderView(
            searchText: $appManager.searchText,
            showingFolderCreation: $showingFolderCreation,
            showingHiddenApps: $showingHiddenApps,
            showingAddCustomApp: $showingAddCustomApp,
            showingSettings: $showingSettings,
            showAllApps: $showAllApps,
            isLoading: appManager.isLoading,
            hiddenAppsCount: folderManager.hiddenAppPaths.count
        ) {
            appManager.isLoading = true
            appManager.loadApplications()
        }
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        if appManager.isLoading {
            VStack {
                ProgressView("Загрузка приложений...")
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            appsGridView
        }
    }
    
    // MARK: - Apps Grid
    private var appsGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: settingsManager.spacing) {
                foldersSection
                appsSection
            }
            .padding()
        }
    }
    
    // MARK: - Folders Section
    private var foldersSection: some View {
        ForEach(folderManager.folders) { folder in
            let appsInFolder = folderManager.getAppsInFolder(folder, from: appManager.filteredApps)
            
            FolderView(
                folder: folder,
                apps: appsInFolder,
                onOpenFolder: {
                    // print("🔵 onOpenFolder вызван для папки '\(folder.name)'")
                    // print("🔵 appsInFolder.count = \(appsInFolder.count)")
                    selectedFolder = folder
                    // print("🔵 selectedFolder установлена для sheet(item:): \(selectedFolder?.name ?? "nil")")
                },
                onEditFolder: {
                    folderToEdit = folder
                },
                onDeleteFolder: {
                    folderManager.deleteFolder(folder)
                },
                onAppDropped: { appPath in
                    handleAppDropped(appPath: appPath, folder: folder)
                }
            )
        }
    }
    
    // MARK: - Apps Section
    private var appsSection: some View {
        ForEach(appsToShow) { app in
            let folderForApp = folderManager.getFolderForApp(app)
            
            AppIconView(
                app: app,
                iconSize: settingsManager.iconSize,
                fontSize: settingsManager.fontSize,
                showAppName: settingsManager.showAppNames
            ) {
                launchApp(app)
            } onAddToFolder: {
                handleAddToFolder(app: app)
            } onHideApp: {
                folderManager.hideApp(app)
            }
            .contextMenu {
                appContextMenu(app: app, folderForApp: folderForApp)
            }
            .scaleEffect(launchingAppId == app.id ? 1.2 : 1)
            .opacity(launchingAppId == app.id ? 0.5 : 1)
        }
    }
    
    private var appsToShow: [AppInfo] {
        showAllApps
            ? folderManager.getVisibleApps(appManager.filteredApps)
            : folderManager.getUnorganizedApps(appManager.filteredApps)
    }
    
    // MARK: - App Context Menu
    @ViewBuilder
    private func appContextMenu(app: AppInfo, folderForApp: VirtualFolder?) -> some View {
        Button("Добавить в папку...") {
            // print("🔵 Контекстное меню: Добавить в папку для '\(app.name)'")
            selectedApp = app
            // print("🔵 selectedApp установлен для sheet: \(selectedApp?.name ?? "nil")")
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
    
    // MARK: - Statistics
    private var statisticsView: some View {
        StatisticsView(
            foldersCount: folderManager.folders.count,
            appsCount: appManager.filteredApps.count,
            hiddenCount: folderManager.hiddenAppPaths.count
        )
    }
    
    // MARK: - Drag Overlay
    @ViewBuilder
    private var dragOverlay: some View {
        DragDropOverlay(isTargeted: isDragTargeted)
    }
    
    // MARK: - Helper Methods
    private func launchApp(_ app: AppInfo) {
        guard !isLaunchingDisabled else { return }
        
        withAnimation(.spring()) {
            launchingAppId = app.id
        }
        isLaunchingDisabled = true
        appManager.launchApplication(app)
        appManager.searchText = ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring()) {
                launchingAppId = nil
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isLaunchingDisabled = false
        }
    }
    
    private func handleAddToFolder(app: AppInfo) {
        // print("🔵 onAddToFolder callback: выбрано приложение '\(app.name)'")
        selectedApp = app
        // print("🔵 selectedApp установлен для sheet(item:): \(selectedApp?.name ?? "nil")")
    }
    
    private func handleAppDropped(appPath: String, folder: VirtualFolder) {
        // print("🔵 onAppDropped вызван с путём: \(appPath)")
        if let app = appManager.applications.first(where: { $0.path == appPath }) {
            // print("🔵 Drag & Drop: добавление '\(app.name)' в папку '\(folder.name)'")
            folderManager.addAppToFolder(app, folder: folder)
        }
    }
    
    // MARK: - Drop Handler
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard !providers.isEmpty else { return false }
        
        var processedCount = 0
        var successCount = 0
        let totalCount = providers.count
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
                    defer {
                        processedCount += 1
                    }
                                       
                    DispatchQueue.main.async {
                        // Пробуем разные способы получения URL
                        var finalURL: URL?
                        
                        // Способ 1: urlData как Data со строкой пути
                        if let urlData = urlData as? Data,
                           let urlString = String(data: urlData, encoding: .utf8) {
                            // Убираем возможные пробелы и переносы строк
                            let cleanedString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
                            finalURL = URL(string: cleanedString) ?? URL(fileURLWithPath: cleanedString)
                        }
                        // Способ 2: urlData напрямую как URL
                        else if let url = urlData as? URL {
                            finalURL = url
                        }
                        // Способ 3: urlData как NSURL
                        else if let nsurl = urlData as? NSURL {
                            finalURL = nsurl as URL
                        }
                        
                        if let url = finalURL {
                            if self.handleDroppedURL(url, silent: totalCount > 1) {
                                successCount += 1
                            }
                        } else {
                            // print("Could not extract URL from dropped item")
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    @discardableResult
    private func handleDroppedURL(_ url: URL, silent: Bool = false) -> Bool {
        // Получаем путь к файлу, убирая file:// схему
        let path = url.path
        
        // Проверяем, что это приложение (.app)
        guard path.hasSuffix(".app") else {
            return false
        }
        
        // Проверяем, что файл существует
        guard FileManager.default.fileExists(atPath: path) else {
            return false
        }
        
        // Проверяем, не добавлено ли уже это приложение
        if appManager.applications.contains(where: { $0.path == path }) {
            return false
        }
        
        // Добавляем приложение
        appManager.addCustomApplication(path: path)
        return true
    }
    
}
