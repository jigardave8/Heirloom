//
//  TreeCanvasView.swift
//  Heirloom
//
//  Created by BitDegree on 13/02/26.
//

import SwiftUI
import CoreData

struct TreeCanvasView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Person.name, ascending: true)],
        animation: .default)
    private var people: FetchedResults<Person>

    // Canvas Logic
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    // Mode Logic
    @State private var isConnectingMode = false
    @State private var sourcePerson: Person? = nil
    
    // UI Presentation
    @State private var selectedPerson: Person?
    @State private var showingGenSettings = false
    @StateObject private var genManager = GenerationManager.shared
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    // LAYER 1: Grid (Background)
                    GridPattern()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        .offset(x: offset.width, y: offset.height)
                        .scaleEffect(scale)
                    
                    // LAYER 2: Connectors (Middle)
                    // We must map nodes to connector lines safely
                    ForEach(people) { person in
                        let parentsArray = (person.parents as? Set<Person> ?? [])
                        ForEach(Array(parentsArray)) { parent in
                            CurvedConnector(
                                start: CGPoint(x: parent.xPosition, y: parent.yPosition),
                                end: CGPoint(x: person.xPosition, y: person.yPosition)
                            )
                            .stroke(
                                LinearGradient(colors: [.gray.opacity(0.6), genManager.colorForGeneration(person.generation)], startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5])
                            )
                        }
                    }
                    .scaleEffect(scale)
                    .offset(offset)
                    
                    // LAYER 3: Nodes (Top)
                    ForEach(people) { person in
                        DraggablePersonNode(
                            person: person,
                            scale: scale,
                            color: getNodeColor(for: person),
                            isConnecting: isConnectingMode,
                            isSelectedSource: sourcePerson == person,
                            onSelect: {
                                handleTap(on: person)
                            },
                            onDelete: {
                                deletePerson(person)
                            }
                        )
                    }
                    .scaleEffect(scale)
                    .offset(offset)
                }
                .contentShape(Rectangle()) // Capture touches on empty space
                
                // --- GESTURES (Pan/Zoom) ---
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { val in
                                let delta = val / lastScale
                                scale *= delta
                                lastScale = val
                            }
                            .onEnded { _ in lastScale = 1.0 },
                        DragGesture()
                            .onChanged { val in
                                let newOffset = CGSize(
                                    width: lastOffset.width + val.translation.width,
                                    height: lastOffset.height + val.translation.height
                                )
                                offset = newOffset
                            }
                            .onEnded { _ in lastOffset = offset }
                    )
                )
                
                // --- UI OVERLAYS ---
                .overlay(alignment: .bottom) {
                    controlBar
                }
                .overlay(alignment: .top) {
                    if isConnectingMode {
                        Text(sourcePerson == nil ? "Select Parent Node" : "Select Child Node to Link")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.75))
                            .clipShape(Capsule())
                            .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Heirloom Tree")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedPerson) { person in
                PersonDetailView(person: person)
            }
            .sheet(isPresented: $showingGenSettings) {
                GenerationSettingsView()
            }
        }
    }
    
    // --- TOOLBAR VIEW ---
    private var controlBar: some View {
        HStack(spacing: 16) {
            // Add Button
            Button(action: addRootPerson) {
                VStack(spacing: 4) {
                    Image(systemName: "person.badge.plus")
                        .font(.title2)
                    Text("Add")
                        .font(.caption2)
                }
            }
            .buttonStyle(.borderedProminent)
            
            // Link Button
            Button(action: toggleConnectionMode) {
                VStack(spacing: 4) {
                    Image(systemName: isConnectingMode ? "xmark" : "link")
                        .font(.title2)
                    Text(isConnectingMode ? "Cancel" : "Connect")
                        .font(.caption2)
                }
            }
            .buttonStyle(.bordered)
            .tint(isConnectingMode ? .red : .blue)
            
            // Color Settings
            Button(action: { showingGenSettings.toggle() }) {
                Image(systemName: "paintpalette.fill")
                    .font(.title2)
                    .padding(8)
                    .background(Material.thin)
                    .clipShape(Circle())
            }
            
            // Reset View
            Button(action: centerView) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .padding(8)
                    .background(Material.thin)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Material.thin)
        .cornerRadius(20)
        .shadow(radius: 5)
        .padding(.bottom, 20)
    }
    
    // --- ACTIONS ---
    
    private func handleTap(on person: Person) {
        if isConnectingMode {
            if sourcePerson == nil {
                // Set Parent
                sourcePerson = person
            } else {
                // Set Child (Create Link)
                linkPeople(parent: sourcePerson!, child: person)
                sourcePerson = nil
                isConnectingMode = false
            }
        } else {
            // Edit Details
            selectedPerson = person
        }
    }
    
    private func linkPeople(parent: Person, child: Person) {
            // 1. Prevent connecting a person to themselves
            guard parent != child else { return }

            // 2. Prevent circular relationships (optional check, good for safety)
            if parent.parents?.contains(child) == true {
                print("Cannot connect: Child is already the Parent's ancestor!")
                return
            }
            
            // 3. Perform the connection with Error Handling
            do {
                // Manually add using key-value coding to ensure update triggers
                let childrenKey = "children"
                
                // This line specifically crashes if "To Many" is not selected in Xcode
                let childrenSet = parent.mutableSetValue(forKey: childrenKey)
                childrenSet.add(child)
                
                // Auto-assign Generation Level
                child.generation = Int16(parent.generation + 1)
                
                // Save changes
                try viewContext.save()
                print("Successfully linked \(parent.name ?? "") to \(child.name ?? "")")
                
            } catch {
                print("CRITICAL ERROR: Could not link people.")
                print("Reason: \(error.localizedDescription)")
                print("Did you set Relationship Type to 'To Many' in the Data Model Inspector?")
            }
        }
    private func deletePerson(_ person: Person) {
        if sourcePerson == person { sourcePerson = nil }
        if selectedPerson == person { selectedPerson = nil }
        
        viewContext.delete(person)
        saveContext()
    }
    
    private func addRootPerson() {
        let newPerson = Person(context: viewContext)
        newPerson.id = UUID()
        newPerson.name = "Relative"
        newPerson.generation = 0
        newPerson.dateOfBirth = Date()
        
        // Place relative to current view
        let centerX = (UIScreen.main.bounds.width / 2 - offset.width) / scale
        let centerY = (UIScreen.main.bounds.height / 2 - offset.height) / scale
        
        newPerson.xPosition = centerX
        newPerson.yPosition = centerY
        
        saveContext()
    }
    
    private func getNodeColor(for person: Person) -> Color {
        if isConnectingMode && sourcePerson == person { return .green }
        return genManager.colorForGeneration(person.generation)
    }
    
    private func toggleConnectionMode() {
        isConnectingMode.toggle()
        sourcePerson = nil
    }
    
    private func centerView() {
        withAnimation {
            scale = 1.0
            offset = .zero
            lastScale = 1.0
            lastOffset = .zero
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving: \(error.localizedDescription)")
        }
    }
}

// --- CORE DATA EXTENSION ---
extension Person {
    /// Safe wrapper to add child using KVC (Key-Value Coding)
    /// Used because "addToChildren" might not be generated depending on build settings
    func addToChildrenSafely(_ child: Person) {
        // The Key Must match CoreData 'children' relationship name
        let key = "children"
        
        // Get the current set of children
        let currentChildren = self.mutableSetValue(forKey: key)
        
        // Add the new child
        currentChildren.add(child)
    }
}
