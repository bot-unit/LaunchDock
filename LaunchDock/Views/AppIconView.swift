//
//  AppIconView.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-06.
//

import SwiftUI
import Cocoa
import Foundation

// App Icon View
struct AppIconView: View {
    let app: AppInfo
    let iconSize: Double
    let fontSize: Double
    let showAppName: Bool
    let onLaunch: () -> Void
    let onAddToFolder: (() -> Void)?
    let onHideApp: (() -> Void)?
    @State private var isHovered = false
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: onLaunch) {
                Image(nsImage: app.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .opacity(isDragging ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                isHovered = hovering
            }
            .onDrag {
                print("🔵 AppIconView.onDrag начат для '\(app.name)'")
                print("   Путь: \(app.path)")
                isDragging = true
                let data = app.path.data(using: .utf8) ?? Data()
                print("   Размер данных: \(data.count) байт")
                return NSItemProvider(item: data as NSData, typeIdentifier: "public.text")
            }
            .onChange(of: isDragging) { oldValue, newValue in
                if oldValue, !newValue {
                    // Задержка для визуального эффекта
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isDragging = false
                    }
                }
            }
            .contextMenu {
                if let onAddToFolder = onAddToFolder {
                    Button("Добавить в папку...") {
                        onAddToFolder()
                    }
                }
                
                if let onHideApp = onHideApp {
                    Button("Скрыть приложение") {
                        onHideApp()
                    }
                }
            }
            
            if showAppName {
                Text(app.name)
                    .font(.system(size: fontSize))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 80)
            }
        }
        .frame(width: 90, height: 100)
    }
}
