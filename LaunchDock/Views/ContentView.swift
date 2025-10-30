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
    @State private var selectedApp: AppInfo? // Используется для .sheet(item:)
    @State private var showAllApps = false // Показывать все приложения или только неорганизованные
    @State private var showingSettings = false
    @State private var showingFolderEdit = false
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
                    print("🔵 ContentView: Создание папки '\(name)' с цветом \(color.rawValue)")
                    folderManager.addFolder(name: name, color: color)
                    print("🔵 ContentView: Текущее количество папок: \(folderManager.folders.count)")
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
            .sheet(isPresented: $showingFolderEdit) {
                if let selectedFolder = selectedFolder {
                    FolderEditSheet(isPresented: $showingFolderEdit, folder: Binding(
                        get: { selectedFolder },
                        set: { self.selectedFolder = $0 }
                    )) { updatedFolder in
                        folderManager.updateFolder(updatedFolder)
                    }
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
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(radius: 24, y: 8)
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
        HStack {
            SearchBar(text: $appManager.searchText)
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
            
            Divider()
            
            Button("Скрытые приложения (\(folderManager.hiddenAppPaths.count))") {
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
                    print("🔵 onOpenFolder вызван для папки '\(folder.name)'")
                    print("🔵 appsInFolder.count = \(appsInFolder.count)")
                    selectedFolder = folder
                    print("🔵 selectedFolder установлена для sheet(item:): \(selectedFolder?.name ?? "nil")")
                },
                onEditFolder: {
                    selectedFolder = folder
                    showingFolderEdit = true
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
            print("🔵 Контекстное меню: Добавить в папку для '\(app.name)'")
            selectedApp = app
            print("🔵 selectedApp установлен для sheet: \(selectedApp?.name ?? "nil")")
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
        HStack {
            Text("Папок: \(folderManager.folders.count) • Приложений: \(appManager.filteredApps.count) • Скрыто: \(folderManager.hiddenAppPaths.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Drag Overlay
    @ViewBuilder
    private var dragOverlay: some View {
        if isDragTargeted {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.accentColor, lineWidth: 3)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.accentColor.opacity(0.1))
                )
                .overlay(
                    VStack(spacing: 12) {
                        Image(systemName: "plus.app.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        Text("Перетащите приложение сюда")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Приложение будет добавлено в LaunchDock")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                )
                .transition(.opacity)
        }
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
        print("🔵 onAddToFolder callback: выбрано приложение '\(app.name)'")
        selectedApp = app
        print("🔵 selectedApp установлен для sheet(item:): \(selectedApp?.name ?? "nil")")
    }
    
    private func handleAppDropped(appPath: String, folder: VirtualFolder) {
        print("🔵 onAppDropped вызван с путём: \(appPath)")
        if let app = appManager.applications.first(where: { $0.path == appPath }) {
            print("🔵 Drag & Drop: добавление '\(app.name)' в папку '\(folder.name)'")
            folderManager.addAppToFolder(app, folder: folder)
        } else {
            print("❌ Drag & Drop: приложение не найдено по пути \(appPath)")
            print("   Доступно приложений: \(appManager.applications.count)")
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
                        if processedCount == totalCount && successCount > 0 {
                            DispatchQueue.main.async {
                                self.showBatchDropSuccess(count: successCount)
                            }
                        }
                    }
                    
                    if let error = error {
                        print("Error loading dropped item: \(error.localizedDescription)")
                        return
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
                            print("Could not extract URL from dropped item")
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
            print("Dropped file is not an application: \(path)")
            if !silent {
                showDropError(message: "Это не приложение. Перетащите файл .app")
            }
            return false
        }
        
        // Проверяем, что файл существует
        guard FileManager.default.fileExists(atPath: path) else {
            print("Application file does not exist at path: \(path)")
            if !silent {
                showDropError(message: "Приложение не найдено по пути: \(path)")
            }
            return false
        }
        
        // Проверяем, не добавлено ли уже это приложение
        if appManager.applications.contains(where: { $0.path == path }) {
            print("Application already exists in the list: \(path)")
            if !silent {
                showDropError(message: "Это приложение уже добавлено")
            }
            return false
        }
        
        // Добавляем приложение
        appManager.addCustomApplication(path: path)
        print("✅ Successfully added application from path: \(path)")
        
        // Показываем успешное уведомление только если не в режиме batch
        if !silent {
            showDropSuccess(appName: url.deletingPathExtension().lastPathComponent)
        }
        
        return true
    }
    
    private func showDropError(message: String) {
        // Можно добавить визуальное уведомление об ошибке
        // Пока просто печатаем в консоль
        print("❌ Drop Error: \(message)")
    }
    
    private func showDropSuccess(appName: String) {
        // Можно добавить визуальное уведомление об успехе
        print("✅ Application '\(appName)' added successfully")
    }
    
    private func showBatchDropSuccess(count: Int) {
        print("✅ Successfully added \(count) application(s)")
    }
}


