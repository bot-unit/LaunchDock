//
//  FolderView.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-06.
//

import SwiftUI
import Cocoa
import Foundation


struct FolderView: View {
    let folder: VirtualFolder
    let apps: [AppInfo]
    let onOpenFolder: () -> Void
    let onEditFolder: () -> Void
    let onDeleteFolder: () -> Void
    let onAppDropped: (String) -> Void
    @State private var isHovered = false
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: onOpenFolder) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(folder.color.color.opacity(isTargeted ? 0.6 : 0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(folder.color.color, lineWidth: isTargeted ? 4 : 2)
                        )
                        .frame(width: 64, height: 64)
                        .scaleEffect(isHovered ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isHovered)
                        .animation(.easeInOut(duration: 0.2), value: isTargeted)
                    
                    // Показываем первые 4 иконки приложений в папке
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 2) {
                        ForEach(Array(apps.prefix(4))) { app in
                            Image(nsImage: app.icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                        }
                    }
                    .frame(width: 40, height: 40)
                    
                    // Счетчик приложений
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("\(apps.count)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(2)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                    }
                    .frame(width: 64, height: 64)
                    
                    // Индикатор drop zone
                    if isTargeted {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [5]))
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                isHovered = hovering
            }
            .onDrop(of: ["public.text"], isTargeted: $isTargeted) { providers in
                // print("🔵 FolderView.onDrop вызван для папки '\(folder.name)'")
                // print("   Количество providers: \(providers.count)")
                
                guard let provider = providers.first else { 
                    // print("❌ FolderView.onDrop: нет providers")
                    return false
                }
                
                provider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
                    if let error = error {
                        // print("❌ FolderView.onDrop: ошибка загрузки: \(error)")
                        return
                    }
                    
                    // print("🔵 FolderView.onDrop: тип data: \(type(of: data))")
                    
                    var appPath: String?
                    
                    // Способ 1: data как URL (временный файл с содержимым)
                    if let url = data as? URL {
                        // print("🔵 Способ 1: data это URL: \(url)")
                        // Читаем содержимое файла
                        if let content = try? String(contentsOf: url, encoding: .utf8) {
                            appPath = content.trimmingCharacters(in: .whitespacesAndNewlines)
                            // print("🔵 Содержимое файла: '\(appPath ?? "nil")'")
                        }
                    }
                    // Способ 2: data как NSURL
                    else if let nsurl = data as? NSURL {
                        let url = nsurl as URL
                        // print("🔵 Способ 2: data это NSURL: \(url)")
                        if let content = try? String(contentsOf: url, encoding: .utf8) {
                            appPath = content.trimmingCharacters(in: .whitespacesAndNewlines)
                            // print("🔵 Содержимое файла: '\(appPath ?? "nil")'")
                        }
                    }
                    // Способ 3: data как Data
                    else if let data = data as? Data {
                        appPath = String(data: data, encoding: .utf8)
                        // print("🔵 Способ 3 (Data): \(appPath ?? "nil")")
                    }
                    // Способ 4: data как NSData
                    else if let nsdata = data as? NSData {
                        appPath = String(data: nsdata as Data, encoding: .utf8)
                        // print("🔵 Способ 4 (NSData): \(appPath ?? "nil")")
                    }
                    // Способ 5: data как String напрямую
                    else if let string = data as? String {
                        appPath = string
                        // print("🔵 Способ 5 (String): \(appPath ?? "nil")")
                    }
                    
                    if let appPath = appPath {
                        // print("✅ FolderView.onDrop: получен путь '\(appPath)'")
                        DispatchQueue.main.async {
                            onAppDropped(appPath)
                        }
                    } else {
                        // print("❌ FolderView.onDrop: не удалось извлечь путь из data")
                        // print("   data = \(String(describing: data))")
                    }
                }
                return true
            }
            .contextMenu {
                Button("Edit") {
                    onEditFolder()
                }
                Button("Delete") {
                    let alert = NSAlert()
                    alert.messageText = "Delete Folder?"
                    alert.informativeText = "Are you sure you want to delete the folder \"\(folder.name)\"? This action cannot be undone."
                    alert.addButton(withTitle: "Delete")
                    alert.addButton(withTitle: "Cancel")
                    alert.alertStyle = .warning
                    
                    if alert.runModal() == .alertFirstButtonReturn {
                        onDeleteFolder()
                    }
                }
            }
            
            Text(folder.name)
                .font(.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 80)
        }
        .frame(width: 90, height: 100)
    }
}
