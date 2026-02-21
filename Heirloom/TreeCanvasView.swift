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
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Person.name, ascending: true)])
    private var people: FetchedResults<Person>

    // Canvas State
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    // Interaction State
    @State private var selectedPerson: Person?
    @StateObject private var genManager = GenerationManager.shared
    @State private var showingGenSettings = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    // 1. Infinite Grid Background
                    GridPattern()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        .offset(x: offset.width, y: offset.height)
                        .scaleEffect(scale)
                    
                    // 2. The Interaction Layer
                    ZStack {
                        // LAYER A: Connecting Lines (The Fix is Here)
                        ForEach(people) { person in
                            // FIX: Safely convert 'parents' Set to an Array
                            let parentsArray = (person.parents as? Set<Person> ?? [])
                            
                            ForEach(Array(parentsArray)) { parent in
                                CurvedConnector(
                                    start: CGPoint(x: parent.xPosition, y: parent.yPosition),
                                    end: CGPoint(x: person.xPosition, y: person.yPosition)
                                )
                                .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5]))
                            }
                        }
                        
                        // LAYER B: Person Nodes
                        ForEach(people) { person in
                            DraggablePersonNode(
                                person: person,
                                scale: scale,
                                color: genManager.colorForGeneration(person.generation),
                                onSelect: { selectedPerson = person }
                            )
                        }
                    }
                    .scaleEffect(scale)
                    .offset(offset)
                }
                // 3. Canvas Gestures
                .contentShape(Rectangle())
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                self.scale *= delta
                                self.lastScale = value
                            }
                            .onEnded { _ in self.lastScale = 1.0 },
                        
                        DragGesture()
                            .onChanged { value in
                                let newOffset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                                self.offset = newOffset
                            }
                            .onEnded { _ in self.lastOffset = self.offset }
                    )
                )
                // 4. Floating Tools
                .overlay(alignment: .bottomTrailing) {
                    HStack {
                        Button(action: { showingGenSettings.toggle() }) {
                            Image(systemName: "paintpalette.fill")
                                .padding()
                                .background(Material.thin)
                                .clipShape(Circle())
                        }
                        
                        Button(action: centerCanvas) {
                            Image(systemName: "location.circle.fill")
                                .font(.title)
                                .padding()
                                .background(Material.thin)
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Family Tree")
            .navigationBarItems(trailing: Button(action: addRootPerson) { Label("Add Root", systemImage: "plus") })
            .sheet(item: $selectedPerson) { person in
                PersonDetailView(person: person)
            }
            .sheet(isPresented: $showingGenSettings) {
                GenerationSettingsView()
            }
        }
    }
    
    private func addRootPerson() {
        let newPerson = Person(context: viewContext)
        newPerson.id = UUID()
        newPerson.name = "New Relative"
        newPerson.generation = 0
        newPerson.dateOfBirth = Date()
        
        // Place relative to current screen center
        let safeX = (UIScreen.main.bounds.width / 2 - offset.width) / scale
        let safeY = (UIScreen.main.bounds.height / 2 - offset.height) / scale
        newPerson.xPosition = safeX
        newPerson.yPosition = safeY
        
        try? viewContext.save()
    }
    
    private func centerCanvas() {
        withAnimation(.spring()) {
            scale = 1.0
            offset = .zero
            lastScale = 1.0
            lastOffset = .zero
        }
    }
}
