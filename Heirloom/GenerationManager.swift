//
//  GenerationManager.swift
//  Heirloom
//
//  Created by BitDegree on 21/02/26.
//

import SwiftUI

class GenerationManager: ObservableObject {
    static let shared = GenerationManager()
    
    // Define a palette of professional colors
    private let distinctColors: [String: Color] = [
        "Royal Blue": Color(red: 0.2, green: 0.3, blue: 0.8),
        "Emerald": Color(red: 0.1, green: 0.6, blue: 0.4),
        "Crimson": Color(red: 0.8, green: 0.2, blue: 0.3),
        "Goldenrod": Color(red: 0.85, green: 0.65, blue: 0.13),
        "Purple": Color(red: 0.5, green: 0.0, blue: 0.5),
        "Teal": Color(red: 0.0, green: 0.5, blue: 0.5),
        "Charcoal": Color(red: 0.2, green: 0.2, blue: 0.2),
        "Burnt Orange": Color(red: 0.8, green: 0.4, blue: 0.0)
    ]
    
    // Save assigned colors to UserDefaults so they persist
    @AppStorage("gen_colors") private var storedAssignments: Data = Data()
    
    func colorForGeneration(_ gen: Int16) -> Color {
        let assignments = getAssignments()
        if let colorName = assignments[Int(gen)], let color = distinctColors[colorName] {
            return color
        }
        return .gray // Default if not set
    }
    
    func getAvailableColors() -> [String] {
        let assigned = getAssignments().values
        return distinctColors.keys.filter { !assigned.contains($0) }.sorted()
    }
    
    func assignColor(_ colorName: String, toGen gen: Int) {
        var assignments = getAssignments()
        assignments[gen] = colorName
        saveAssignments(assignments)
    }
    
    // Private Helpers for Persistence
    private func getAssignments() -> [Int: String] {
        guard let decoded = try? JSONDecoder().decode([Int: String].self, from: storedAssignments) else { return [:] }
        return decoded
    }
    
    private func saveAssignments(_ assignments: [Int: String]) {
        if let encoded = try? JSONEncoder().encode(assignments) {
            storedAssignments = encoded
        }
    }
}
