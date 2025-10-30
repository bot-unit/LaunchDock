//
//  AddToFolderSheet.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-06.
//

import SwiftUI
import Cocoa
import Foundation


// Add To Folder Sheet
struct AddToFolderSheet: View {
    let app: AppInfo
    @ObservedObject var folderManager: FolderManager
    @Binding var isPresented: Bool
    let onAddToFolder: (VirtualFolder) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Добавить \(app.name) в папку")
                .font(.title2)
                .fontWeight(.bold)
            
            if folderManager.folders.isEmpty {
                Text("Нет доступных папок")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                Text("Доступно папок: \(folderManager.folders.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                        ForEach(folderManager.folders) { folder in
                            Button(action: {
                                onAddToFolder(folder)
                                isPresented = false
                            }) {
                                VStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(folder.color.color.opacity(0.3))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(folder.color.color, lineWidth: 2)
                                        )
                                        .frame(width: 50, height: 50)
                                    
                                    Text(folder.name)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 300)
            }
            
            Button("Отмена") {
                isPresented = false
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            print("📂 AddToFolderSheet открыт для приложения '\(app.name)'")
            print("   Передано папок: \(folderManager.folders.count)")
            for folder in folderManager.folders {
                print("   - '\(folder.name)' (ID: \(folder.id), приложений: \(folder.appPaths.count))")
            }
        }
    }
}
