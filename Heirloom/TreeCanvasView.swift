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

    // Zoom and Pan States
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    // Navigation for Detail View
    @State private var selectedPerson: Person?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Pattern (Optional)
                Color.init(uiColor: .systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                // The Infinite Canvas
                GeometryReader { proxy in
                    ZStack {
                        // LAYER 1: Lines connecting families (To be implemented with Path)
                        
                        // LAYER 2: People Nodes
                        ForEach(people) { person in
                            PersonNodeView(person: person)
                                .position(x: person.xPosition, y: person.yPosition)
                                .onTapGesture {
                                    selectedPerson = person
                                }
                                // Simple Drag logic to move nodes manually for now
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            person.xPosition = value.location.x
                                            person.yPosition = value.location.y
                                        }
                                        .onEnded { _ in
                                            saveContext()
                                        }
                                )
                        }
                    }
                    .scaleEffect(scale)
                    .offset(offset)
                    // Zoom and Pan Gestures
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    scale *= delta
                                    lastScale = value
                                }
                                .onEnded { _ in lastScale = 1.0 },
                            DragGesture()
                                .onChanged { value in
                                    let newOffset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                    offset = newOffset
                                }
                                .onEnded { value in
                                    lastOffset = offset
                                }
                        )
                    )
                }
            }
            .navigationTitle("Heirloom Tree")
            .navigationBarItems(trailing: Button(action: addPerson) {
                Label("Add Root", systemImage: "plus")
            })
            .sheet(item: $selectedPerson) { person in
                PersonDetailView(person: person)
            }
        }
    }
    
    private func addPerson() {
        let newPerson = Person(context: viewContext)
        newPerson.id = UUID()
        newPerson.name = "New Relative"
        newPerson.xPosition = 200 // Default Center-ish
        newPerson.yPosition = 300
        newPerson.dateOfBirth = Date()
        saveContext()
    }
    
    private func saveContext() {
        do { try viewContext.save() } catch { print(error) }
    }
}
