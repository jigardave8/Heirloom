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
    @State private var generationLevel: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. Header View (Icon & Basic Info)
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
                    // TAB 0: Editing Form
                    infoFormView
                        .tag(0)

                    // TAB 1: Photo Grid
                    GalleryGridView(person: person)
                        .tag(1)

                    // TAB 2: PDF/Book List
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
                // Initialize temp state from Core Data
                inputName = person.name ?? ""
                generationLevel = Int(person.generation)
            }
        }
    }

    // MARK: - Extracted View Components
    // (Keeps the main body simple so the compiler is fast)

    private var headerSection: some View {
        HStack {
            // Placeholder Avatar
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(Image(systemName: "person.fill").font(.largeTitle).foregroundColor(.gray))
            
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
                
                // --- NEW: GENERATION CONTROLLER ---
                // Changes here effect the color on the tree
                HStack {
                    Text("Generation Level")
                    Spacer()
                    Stepper(value: $generationLevel, in: 0...20) {
                        Text("\(generationLevel)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Biography")) {
                // Connects to 'desc' attribute in CoreData
                TextEditor(text: bioBinding)
                    .frame(height: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            Section(footer: Text("Set the Generation Level to automatically color-code this person on the main tree (e.g., Grandparents = 0, Parents = 1).")) {
                EmptyView()
            }
        }
    }

    // MARK: - Helper Bindings
    // (Solving dynamic lookup errors safely)
    
    // 1. Safe Binding for Date
    private var dateBinding: Binding<Date> {
        Binding<Date>(
            get: { self.person.dateOfBirth ?? Date() },
            set: { self.person.dateOfBirth = $0 }
        )
    }

    // 2. Safe Binding for Biography (Description)
    private var bioBinding: Binding<String> {
        Binding<String>(
            get: {
                // Safely handle nil 'desc'
                return self.person.desc ?? ""
            },
            set: { newValue in
                self.person.desc = newValue
            }
        )
    }

    // 3. Display Logic
    private var formattedBirthDate: String {
        person.dateOfBirth?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown"
    }

    // MARK: - Saving Logic
    private func saveChanges() {
        // Commit UI State to Core Data Object
        person.name = inputName
        person.generation = Int16(generationLevel)
        
        // Save Context
        do {
            try viewContext.save()
        } catch {
            print("Error saving details: \(error.localizedDescription)")
        }
    }
}
