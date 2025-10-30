//
//  FolderAppsView.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-06.
//

import SwiftUI
import Cocoa
import Foundation


// Folder Apps View
struct FolderAppsView: View {
    let folder: VirtualFolder
    let apps: [AppInfo]
    let iconSize: Double
    let fontSize: Double
    let spacing: Double
    let showAppNames: Bool
    @Binding var isPresented: Bool
    let onLaunchApp: (AppInfo) -> Void
    let onRemoveApp: (AppInfo) -> Void
    let onHideApp: (AppInfo) -> Void
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)
    
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
                
                Text(folder.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            if apps.isEmpty {
                VStack {
                    Text("Папка пуста")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Добавьте приложения через контекстное меню")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: spacing) {
                        ForEach(apps) { app in
                            AppIconView(app: app, iconSize: iconSize, fontSize: fontSize, showAppName: showAppNames) {
                                onLaunchApp(app)
                                isPresented = false
                            } onAddToFolder: {
                                // В контексте папки - удаление
                                onRemoveApp(app)
                            } onHideApp: {
                                onHideApp(app)
                            }
                            .contextMenu {
                                Button("Удалить из папки") {
                                    onRemoveApp(app)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .padding()
        .frame(width: 600, height: 400)
        .onAppear {
            /*
            print("📂 FolderAppsView открыт для папки '\(folder.name)'")
            print("   ID папки: \(folder.id)")
            print("   Количество путей в папке: \(folder.appPaths.count)")
            print("   Пути: \(folder.appPaths)")
            print("   Передано приложений для отображения: \(apps.count)")
            for app in apps {
                print("   - '\(app.name)' (\(app.path))")
            }
            */
        }
    }
}
