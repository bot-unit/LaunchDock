//
//  FolderEditSheet.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-26.
//

import SwiftUI

struct FolderEditSheet: View {
    @Binding var isPresented: Bool
    @Binding var folder: VirtualFolder
    let onSaveFolder: (VirtualFolder) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Folder")
                .font(.title2)
                .fontWeight(.bold)
            
            TextField("Folder Name", text: $folder.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            VStack(alignment: .leading) {
                Text("Folder Color:")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                    ForEach(VirtualFolder.FolderColor.allCases, id: \.self) { color in
                        Button(action: {
                            folder.color = color
                        }) {
                            Circle()
                                .fill(color.color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: folder.color == color ? 3 : 0)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                
                Spacer()
                
                Button("Save") {
                    onSaveFolder(folder)
                    isPresented = false
                }
                .disabled(folder.name.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
