//
//  FolderCreationSheet.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-06.
//

import SwiftUI
import Cocoa
import Foundation

// Folder Creation Sheet
struct FolderCreationSheet: View {
    @Binding var isPresented: Bool
    @State private var folderName = ""
    @State private var selectedColor: VirtualFolder.FolderColor = .blue
    let onCreateFolder: (String, VirtualFolder.FolderColor) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Создать папку")
                .font(.title2)
                .fontWeight(.bold)
            
            TextField("Название папки", text: $folderName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            VStack(alignment: .leading) {
                Text("Цвет папки:")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                    ForEach(VirtualFolder.FolderColor.allCases, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                        }) {
                            Circle()
                                .fill(color.color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            HStack {
                Button("Отмена") {
                    isPresented = false
                }
                
                Spacer()
                
                Button("Создать") {
                    if !folderName.isEmpty {
                        onCreateFolder(folderName, selectedColor)
                        isPresented = false
                        folderName = ""
                        selectedColor = .blue
                    }
                }
                .disabled(folderName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
