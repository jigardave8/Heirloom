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
    @State private var generationLevel: Int = 0
    @State private var selectedTab = 0
    
    
    @State private var showPhotoPicker = false


    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                    .padding()
                
                Picker("Tabs", selection: $selectedTab) {
                    Text("Info").tag(0)
                    Text("Gallery").tag(1)
                    Text("Documents").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Divider().padding(.top, 8)

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
                generationLevel = Int(person.generation)
            }
        }
    }

    // MARK: - Extracted Views
    private var headerSection: some View {
        HStack {
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
                            
                            // *** CHANGE THIS LINE ***
                            DatePicker("Date of Death", selection: dateOfDeathBindingForPicker, displayedComponents: .date)
                                .datePickerStyle(.compact)
                
                HStack {
                    Text("Generation Level")
                    Spacer()
                    Stepper(value: $generationLevel, in: 0...20) {
                        Text("\(generationLevel)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // --- PARTNER MANAGEMENT SECTION ---
            Section(header: Text("Partner/Spouse")) {
                if let partner = person.partnersArray?.first {
                    HStack {
                        Text("Linked To:")
                        NavigationLink(partner.name ?? "Unknown", destination: PersonDetailView(person: partner))
                        Spacer()
                        Button("Unlink", role: .destructive) { unlinkPartner(partner) }
                    }
                } else {
                    Text("Use the 'Connect' mode on the Tree Canvas to link a Partner/Spouse.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Biography")) {
                TextEditor(text: bioBinding)
                    .frame(height: 150)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            }
        }
    }

    // MARK: - Helpers & Bindings
    
    private var formattedBirthDate: String { person.dateOfBirth?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown" }

    private var dateBinding: Binding<Date> {
        Binding<Date>(
            get: { person.dateOfBirth ?? Date() },
            set: { person.dateOfBirth = $0 }
        )
    }
    
    private var deathDateBinding: Binding<Date?> { // <-- THIS IS CORRECT (Returns Optional)
          Binding<Date?>(
              get: { person.dateOfDeath },
              set: { person.dateOfDeath = $0 }
          )
      }
      
      // ADD THIS NEW HELPER FUNCTION TO FIX THE ERROR:
      private var dateOfDeathBindingForPicker: Binding<Date> {
          Binding<Date>(
              get: {
                  // If person.dateOfDeath is nil, use now. This satisfies the non-optional requirement.
                  return person.dateOfDeath ?? Date()
              },
              set: { newValue in
                  // When the user changes the date, set the person's *optional* date to that new date.
                  // If the user clears the date later, we need a way to set it to nil,
                  // which requires more advanced UI or logic than a standard optional DatePicker.
                  person.dateOfDeath = newValue
              }
          )
      }
    private var bioBinding: Binding<String> {
        Binding<String>(
            get: { return self.person.desc ?? "" },
            set: { self.person.desc = $0 }
        )
    }
    
    private func unlinkPartner(_ partner: Person) {
        person.mutableSetValue(forKey: "partners").remove(partner)
        partner.mutableSetValue(forKey: "partners").remove(person)
        try? viewContext.save()
    }

    // MARK: - Saving
    private func saveChanges() {
        person.name = inputName
        person.generation = Int16(generationLevel)
        try? viewContext.save()
    }
}

// Extension to safely read partners array
extension Person {
    var partnersArray: [Person]? {
        return partners?.allObjects as? [Person]
    }
}
