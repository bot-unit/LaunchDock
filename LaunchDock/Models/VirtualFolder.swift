//
//  VirtualFolder.swift
//  LaunchDock
//
//  Created by Igor Unit on 2025-10-03.
//

import SwiftUI

struct VirtualFolder: Identifiable, Codable {
    var id: UUID
    var name: String
    var appPaths: Set<String>
    var color: FolderColor
    
    enum FolderColor: String, CaseIterable, Codable {
        case blue = "blue"
        case green = "green"
        case orange = "orange"
        case red = "red"
        case purple = "purple"
        case pink = "pink"
        case yellow = "yellow"
        case gray = "gray"
        
        var color: Color {
            switch self {
            case .blue: return .blue
            case .green: return .green
            case .orange: return .orange
            case .red: return .red
            case .purple: return .purple
            case .pink: return .pink
            case .yellow: return .yellow
            case .gray: return .gray
            }
        }
    }
    
    init(id: UUID = UUID(), name: String, appPaths: Set<String>, color: FolderColor) {
        self.id = id
        self.name = name
        self.appPaths = appPaths
        self.color = color
    }
}
