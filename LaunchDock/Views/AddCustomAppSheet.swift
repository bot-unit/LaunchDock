//
//  AddCustomAppSheet.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-26.
//

import SwiftUI
import UniformTypeIdentifiers

struct AddCustomAppSheet: View {
    @Binding var isPresented: Bool
    let onAddApp: (URL) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Custom Application")
                .font(.title2)
                .fontWeight(.bold)
            
            Button("Select Application") {
                let openPanel = NSOpenPanel()
                openPanel.allowedContentTypes = [.application]
                openPanel.allowsMultipleSelection = false
                openPanel.canChooseDirectories = false
                openPanel.canChooseFiles = true
                
                if openPanel.runModal() == .OK {
                    if let url = openPanel.url {
                        onAddApp(url)
                        isPresented = false
                    }
                }
            }
            
            Button("Cancel") {
                isPresented = false
            }
        }
        .padding()
        .frame(width: 400)
    }
}

