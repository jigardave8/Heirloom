//
//  GenerationSettingsView.swift
//  Heirloom
//
//  Created by BitDegree on 21/02/26.
//

import SwiftUI

struct GenerationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var genManager = GenerationManager.shared
    
    @State private var selectedGen: Int = 0
    @State private var selectedColorName: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Assign Generation Color")) {
                    Stepper("Generation: \(selectedGen)", value: $selectedGen, in: 0...10)
                    
                    // The Dropdown logic
                    Picker("Select Color", selection: $selectedColorName) {
                        Text("Select...").tag("")
                        // Filter Logic: Show only unused colors!
                        ForEach(genManager.getAvailableColors(), id: \.self) { colorName in
                            Text(colorName).tag(colorName)
                        }
                    }
                    
                    Button("Lock Color") {
                        if !selectedColorName.isEmpty {
                            genManager.assignColor(selectedColorName, toGen: selectedGen)
                            selectedColorName = "" // Reset
                        }
                    }
                    .disabled(selectedColorName.isEmpty)
                }
                
                Section(header: Text("Instructions")) {
                    Text("Gen 0 = Grandparents/Roots\nGen 1 = Parents\nGen 2 = Children")
                        .font(.caption)
                }
            }
            .navigationTitle("Styles")
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}
