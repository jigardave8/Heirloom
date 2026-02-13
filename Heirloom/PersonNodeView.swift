//
//  PersonNodeView.swift
//  Heirloom
//
//  Created by BitDegree on 13/02/26.
//

import SwiftUI

struct PersonNodeView: View {
    @ObservedObject var person: Person // Observe changes
    
    var body: some View {
        VStack {
            // Placeholder for Profile Image
            Circle()
            
                .fill(Color.orange.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.orange)
                )
            
            Text(person.name ?? "Unknown")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(person.dateOfBirth ?? Date(), style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Material.regular)
        .cornerRadius(12)
        .shadow(radius: 4)
        .frame(width: 150, height: 120)
    }
}
