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

    @State private var inputName: String = ""
    @State private var generationLevel: Int = 0
    @State private var selectedTab = 0
    @State private var showPhotoPicker = false
    @State private var isLinkingPartner = false

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
        // FIX: Removed incorrect conditional check here, now passes the non-optional 'person'
        .sheet(isPresented: $isLinkingPartner) {
            PartnerSelectionView(
                personA: person,
                isLinkingPartner: $isLinkingPartner
            )
        }
    }

    // MARK: - Extracted Views
    private var headerSection: some View {
        HStack {
            Button(action: { showPhotoPicker = true }) {
                profileImageView
            }
            
            VStack(alignment: .leading) {
                TextField("Name", text: $inputName)
                    .font(.title2).bold()
                    .textFieldStyle(.roundedBorder)
                
                Text("Born: \(formattedBirthDate)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            Text("Implement Photo Picker for Profile Pic Here: Save to person.profilePicFileName").padding()
        }
    }
    
    private var profileImageView: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 80)
            
            if let fileName = person.profilePicFileName {
                Image(systemName: "person.crop.square.fill.and.at.rectangle")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            } else {
                Image(systemName: "person.fill.viewfinder")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            }
        }
        .clipShape(Circle())
    }
    
    private var infoFormView: some View {
        Form {
            Section(header: Text("Life Events")) {
                DatePicker("Birth Date", selection: dateBinding, displayedComponents: .date)
                
                // FIX: MUST use the wrapper binding to handle optional date conversion for the picker
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
                } else if !isLinkingPartner {
                    Button("Link New Partner") {
                        isLinkingPartner = true
                    }
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
        Binding<Date>(get: { person.dateOfBirth ?? Date() }, set: { person.dateOfBirth = $0 })
    }
    
    // FIX APPLIED HERE: Correct wrapper binding to satisfy DatePicker's non-optional requirement
    private var dateOfDeathBindingForPicker: Binding<Date> {
        Binding<Date>(
            get: { person.dateOfDeath ?? Date() },
            set: { person.dateOfDeath = $0 }
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

// --- NEW HELPER VIEW: Partner Selection ---
struct PartnerSelectionView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.dismiss) var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Person.name, ascending: true)],
        animation: .default
    )
    private var allPeople: FetchedResults<Person>
    
    @ObservedObject var personA: Person
    @Binding var isLinkingPartner: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(allPeople) { potentialPartner in
                    if potentialPartner != personA && !(personA.partnersArray?.contains(potentialPartner) ?? false) {
                        
                        Button(action: { linkPartner(partnerB: potentialPartner) }) {
                            HStack {
                                Text(potentialPartner.name ?? "Unknown")
                                Spacer()
                                Text("Gen \(potentialPartner.generation)")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Partner for \(personA.name ?? "Self")")
            .navigationBarItems(trailing: Button("Cancel") { isLinkingPartner = false })
        }
    }
    
    private func linkPartner(partnerB: Person) {
        // Set the bidirectional link for 'partners' relationship
        personA.mutableSetValue(forKey: "partners").add(partnerB)
        partnerB.mutableSetValue(forKey: "partners").add(personA)
        
        try? viewContext.save()
        
        isLinkingPartner = false
    }
}
