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
                    ForEach(people) { person in
                        // 1. DRAW CHILD CONNECTIONS (Parent -> Child)
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
                        
                        // 2. DRAW PARTNER CONNECTIONS (Spouse)
                        if let partner = person.partnersArray?.first,
                           person.xPosition < partner.xPosition {
                            CurvedConnector(
                                start: CGPoint(x: person.xPosition, y: person.yPosition - 40),
                                end: CGPoint(x: partner.xPosition, y: partner.yPosition - 40)
                            )
                            .stroke(
                                Color.blue.opacity(0.5),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
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
                            onSelect: { handleTap(on: person) },
                            onDelete: { deletePerson(person) }
                        )
                    }
                    .scaleEffect(scale)
                    .offset(offset)
                }
                .contentShape(Rectangle())
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
                .overlay(alignment: .bottom) { controlBar }
                .overlay(alignment: .top) {
                    if isConnectingMode {
                        Text(sourcePerson == nil ? "Select PARENT Node" : "Select CHILD Node to Link")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.75))
                            .clipShape(Capsule())
                            .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Family Tree")
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
            Button(action: addRootPerson) {
                VStack(spacing: 4) { Image(systemName: "person.badge.plus").font(.title2); Text("Add").font(.caption2) }
            }
            .buttonStyle(.borderedProminent)
            
            Button(action: toggleConnectionMode) {
                VStack(spacing: 4) { Image(systemName: isConnectingMode ? "xmark" : "link").font(.title2); Text(isConnectingMode ? "Cancel" : "Connect").font(.caption2) }
            }
            .buttonStyle(.bordered)
            .tint(isConnectingMode ? .red : .blue)
            
            Button(action: { showingGenSettings.toggle() }) {
                Image(systemName: "paintpalette.fill").font(.title2).padding(8).background(Material.thin).clipShape(Circle())
            }
            
            Button(action: { print("Timeline button pressed! Next feature.") }) {
                Image(systemName: "clock.fill").font(.title2).padding(8).background(Material.thin).clipShape(Circle())
            }
            
            Button(action: triggerAutoLayout) {
                Image(systemName: "arrow.down.to.line.square").font(.title2).padding(8).background(Material.thin).clipShape(Circle())
            }
            
            Button(action: centerView) {
                Image(systemName: "location.fill").font(.title2).padding(8).background(Material.thin).clipShape(Circle())
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
                sourcePerson = person
            } else {
                linkPeople(parent: sourcePerson!, child: person)
                sourcePerson = nil
                isConnectingMode = false
            }
        } else {
            selectedPerson = person
        }
    }
    
    private func linkPeople(parent: Person, child: Person) {
        guard parent != child else { return }
        
        parent.addToChildrenSafely(child)
        child.generation = Int16(parent.generation + 1)
        
        saveContext()
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
        do { try viewContext.save() } catch { print("Error saving: \(error.localizedDescription)") }
    }
    
    // --- AUTO-LAYOUT LOGIC (UPDATED FOR SPOUSE HANDLING) ---
    
    private func triggerAutoLayout() {
        guard !people.isEmpty else { return }
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            let layoutMap = calculateTreeLayout()
            
            for (person, position) in layoutMap {
                person.xPosition = position.x
                person.yPosition = position.y
            }
            
            centerView()
            saveContext()
        }
    }

    private func calculateTreeLayout() -> [Person: CGPoint] {
        var layout: [Person: CGPoint] = [:]
        let allPeople = Array(people.sorted(by: { $0.generation < $1.generation }))
        
        let verticalSpacing: CGFloat = 180.0 // Increased vertical gap for spouse line
        let horizontalSpacing: CGFloat = 100.0
        
        // 1. Pass to assign generation-based X-position placeholder (Y is level index * verticalSpacing)
        var peopleByGen: [Int16: [Person]] = [:]
        for person in allPeople {
            peopleByGen[person.generation, default: []].append(person)
        }
        
        var currentTotalX: CGFloat = 0.0
        
        // 2. Process each generation level to place couples side-by-side
        for (gen, var members) in peopleByGen.sorted(by: { $0.key < $1.key }) {
            
            var currentX: CGFloat = currentTotalX
            var levelMembers: [Person] = []
            
            // Sort the group to put linked spouses/partners together
            // Grouping logic: Find an unprocessed person, find their spouse, process them as a pair/block.
            while let root = members.first(where: { !layout.keys.contains($0) }) {
                levelMembers.append(root)
                let spouses = (root.partners as? Set<Person> ?? []).filter { layout.keys.contains($0) == false && $0.generation == gen }
                levelMembers.append(contentsOf: spouses)
                
                // Remove all processed members from the remaining pool
                members.removeAll(where: { levelMembers.contains($0) })
            }
            
            // 3. Assign final X/Y positions to the block of people in this level
            let groupWidth = CGFloat(levelMembers.count) * horizontalSpacing
            let startX = currentX - (groupWidth / 2) // Center the group around the previous offset
            let baseY = CGFloat(gen) * verticalSpacing
            
            for (index, person) in levelMembers.enumerated() {
                layout[person] = CGPoint(x: startX + (CGFloat(index) * horizontalSpacing), y: baseY)
            }
            
            // Advance the offset for the next generation
            currentTotalX += groupWidth + horizontalSpacing
        }
        
        return layout
    }
    
    private func distributeSubtree(person: Person, layout: inout [Person: CGPoint], horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        // Recursive function remains the same: Child Y = Parent Y + VerticalSpacing
        
        let children = (person.children as? Set<Person> ?? []).filter { child in
            (child.parents as? Set<Person> ?? []).count == 1 && (child.parents as? Set<Person> == [person])
        }
        
        if !children.isEmpty {
            let childCount = CGFloat(children.count)
            let totalBranchWidth = (childCount - 1) * horizontalSpacing
            let parentX = layout[person]?.x ?? 0
            let childY = (layout[person]?.y ?? 0) + verticalSpacing // This Y value will be overridden by the top-level loop, but we use it for relative positioning if needed.
            
            let startX = parentX - (totalBranchWidth / 2)
            
            let sortedChildren = children.sorted { $0.name ?? "" < $1.name ?? "" }
            
            for (index, child) in sortedChildren.enumerated() {
                let childX = startX + (CGFloat(index) * horizontalSpacing)
                layout[child] = CGPoint(x: childX, y: childY)
                
                distributeSubtree(person: child, layout: &layout, horizontalSpacing: horizontalSpacing, verticalSpacing: verticalSpacing)
            }
        }
    }
}
// --- CORE DATA EXTENSION (MUST BE AT THE END OF THE FILE) ---
extension Person {
    func addToChildrenSafely(_ child: Person) {
        let key = "children"
        let currentChildren = self.mutableSetValue(forKey: key)
        currentChildren.add(child)
    }
}
