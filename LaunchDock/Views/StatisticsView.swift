//
//  StatisticsView.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-30.
//

import SwiftUI

/// Компонент для отображения статистики
struct StatisticsView: View {
    let foldersCount: Int
    let appsCount: Int
    let hiddenCount: Int
    
    var body: some View {
        HStack {
            Text("Папок: \(foldersCount) • Приложений: \(appsCount) • Скрыто: \(hiddenCount)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal)
    }
}
