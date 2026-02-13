//
//  PersonDetailView.swift
//  Heirloom
//
//  Created by BitDegree on 13/02/26.
//

//
//  PersonDetailView.swift
//  Heirloom
//
//  Created by BitDegree on 13/02/26.
//

import SwiftUI
import CoreData
import PhotosUI

struct PersonDetailView: View {
    @ObservedObject var person: Person
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    // UI States
    @State private var inputName: String = ""
    @State private var selectedTab = 0
    
    // Unused state removed for cleaner code if not strictly needed immediately
    // @State private var inputImage: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. Header View
                headerSection
                    .padding()
                
                // 2. Tab Picker
                Picker("Tabs", selection: $selectedTab) {
                    Text("Info").tag(0)
                    Text("Gallery").tag(1)
                    Text("Documents").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Divider().padding(.top, 8)

                // 3. Main Content
                TabView(selection: $selectedTab) {
                    infoFormView
                        .tag(0)

                    GalleryGridView(person: person)
                        .tag(1)

                    DocumentsListView(person: person)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(person.name ?? "Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .onAppear {
                inputName = person.name ?? ""
            }
        }
    }

    // MARK: - Extracted Views (Fixes Compiler Timing Out)
    
    private var headerSection: some View {
        HStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(Image(systemName: "person.fill").font(.largeTitle))
            
            VStack(alignment: .leading) {
                TextField("Name", text: $inputName)
                    .font(.title2).bold()
                    .textFieldStyle(.roundedBorder)
                
                Text("Born: \(formattedBirthDate)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var infoFormView: some View {
        Form {
            Section(header: Text("Life Events")) {
                DatePicker("Birth Date", selection: dateBinding, displayedComponents: .date)
            }
            
            Section(header: Text("Biography")) {
                // Assumes your CoreData entity 'Person' has a 'desc' string attribute
                // If it's named 'summary' or something else, change 'person.desc' below
                TextEditor(text: bioBinding)
                    .frame(height: 150)
            }
        }
    }

    // MARK: - Helpers & Bindings
    
    // Simplifies the date string calculation for the compiler
    private var formattedBirthDate: String {
        person.dateOfBirth?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown"
    }

    // Moves the complex binding logic out of the body
    private var dateBinding: Binding<Date> {
        Binding(
            get: { person.dateOfBirth ?? Date() },
            set: { person.dateOfBirth = $0 }
        )
    }

    // Corrected Binding Logic
        private var bioBinding: Binding<String> {
            Binding<String>(
                get: {
                    // Return empty string if desc is nil
                    return self.person.desc ?? ""
                },
                set: { newValue in
                    // Update the person object
                    self.person.desc = newValue
                }
            )
        }

    private func saveChanges() {
        person.name = inputName
        // Note: Attribute changes like dateOfBirth are bound directly via the computed properties above
        try? viewContext.save()
    }
}
