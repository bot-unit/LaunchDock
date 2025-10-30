//
//  DragDropOverlay.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-30.
//

import SwiftUI

/// Оверлей для отображения индикатора перетаскивания
struct DragDropOverlay: View {
    let isTargeted: Bool
    
    var body: some View {
        if isTargeted {
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
}
