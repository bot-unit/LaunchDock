//
//  UpdatesCheckView.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-30.
//

import SwiftUI

/// View для отображения доступных обновлений приложений
struct UpdatesCheckView: View {
    @Binding var isPresented: Bool
    let apps: [AppInfo]
    
    @State private var updates: [AppUpdate] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private let updateChecker = UpdateCheckerService()
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Проверка обновлений")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Закрыть") {
                    isPresented = false
                }
            }
            .padding()
            
            Divider()
            
            // Content
            if isLoading {
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Проверка обновлений...")
                        .font(.headline)
                    Text("Это может занять некоторое время")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text("Ошибка")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                updatesList
            }
        }
        .frame(width: 700, height: 500)
        .task {
            await checkUpdates()
        }
    }
    
    // MARK: - Updates List
    
    private var updatesList: some View {
        VStack(alignment: .leading, spacing: 10) {
            if updatesAvailableCount > 0 {
                // Статистика
                HStack {
                    Text("\(updatesAvailableCount) обновлений доступно")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                
                Divider()
                
                // Список обновлений
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(updatesWithAvailableUpdates) { update in
                            UpdateRowView(update: update)
                            Divider()
                        }
                    }
                }
            } else {
                // Нет обновлений
                VStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    Text("Все приложения обновлены")
                        .font(.headline)
                    Text("Проверено \(updates.count) приложений")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
    
    private var updatesAvailableCount: Int {
        updates.filter { $0.updateAvailable }.count
    }
    
    private var updatesWithAvailableUpdates: [AppUpdate] {
        updates.filter { $0.updateAvailable }
    }
    
    // MARK: - Actions
    
    private func checkUpdates() async {
        isLoading = true
        errorMessage = nil
        
        let results = await updateChecker.checkForUpdates(apps: apps)
        
        updates = results.sorted { app1, app2 in
            // Сначала приложения с доступными обновлениями
            if app1.updateAvailable != app2.updateAvailable {
                return app1.updateAvailable
            }
            // Затем по алфавиту
            return app1.appName < app2.appName
        }
        
        isLoading = false
    }
}

// MARK: - Update Row View

struct UpdateRowView: View {
    let update: AppUpdate
    
    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            // Иконка статуса
            Image(systemName: update.updateAvailable ? "arrow.up.circle.fill" : "checkmark.circle")
                .font(.title2)
                .foregroundColor(update.updateAvailable ? .green : .secondary)
                .frame(width: 30)
            
            // Название приложения
            VStack(alignment: .leading, spacing: 4) {
                Text(update.appName)
                    .font(.headline)
                
                Text(sourceDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Версии
            VStack(alignment: .trailing, spacing: 4) {
                if update.updateAvailable, let availableVersion = update.availableVersion {
                    HStack(spacing: 5) {
                        Text(update.currentVersion)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(availableVersion)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                } else if let availableVersion = update.availableVersion {
                    Text(availableVersion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text(update.currentVersion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if !update.updateAvailable && update.availableVersion != nil {
                    Text("Актуальная версия")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else if update.availableVersion == nil {
                    Text("Не удалось проверить")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(update.updateAvailable ? Color.green.opacity(0.05) : Color.clear)
    }
    
    private var sourceDescription: String {
        switch update.updateSource {
        case .sparkle:
            return "Обновляется через Sparkle"
        case .macAppStore:
            return "Mac App Store"
        case .none:
            return "Нет источника обновлений"
        }
    }
}

#Preview {
    UpdatesCheckView(
        isPresented: .constant(true),
        apps: []
    )
}
