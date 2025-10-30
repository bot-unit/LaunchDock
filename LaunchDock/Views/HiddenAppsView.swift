//
//  HiddenAppsView.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-07.
//
import SwiftUI
import Cocoa
import Foundation


// Hidden Apps View
struct HiddenAppsView: View {
    let hiddenApps: [AppInfo]
    let iconSize: Double
    let fontSize: Double
    let spacing: Double
    let showAppNames: Bool
    @Binding var isPresented: Bool
    let onShowApp: (AppInfo) -> Void
    let onLaunchApp: (AppInfo) -> Void
    
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
                
                Text("Скрытые приложения")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("(\(hiddenApps.count))")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            if hiddenApps.isEmpty {
                VStack {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Нет скрытых приложений")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("Используйте контекстное меню для скрытия приложений")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: spacing) {
                        ForEach(hiddenApps) { app in
                            VStack(spacing: 8) {
                                Button(action: {
                                    onLaunchApp(app)
                                }) {
                                    Image(nsImage: app.icon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: iconSize, height: iconSize)
                                        .opacity(0.6) // Полупрозрачность для скрытых
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button("Показать приложение") {
                                        onShowApp(app)
                                    }
                                    
                                    Button("Запустить") {
                                        onLaunchApp(app)
                                    }
                                }
                                
                                if showAppNames {
                                    Text(app.name)
                                        .font(.system(size: fontSize))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .frame(width: 80)
                                }
                            }
                            .frame(width: 90, height: 100)
                        }
                    }
                    .padding()
                }
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }
}
