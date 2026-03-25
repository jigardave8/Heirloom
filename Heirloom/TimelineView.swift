//
//  TimelineView.swift
//  Heirloom
//
//  Created by BitDegree on 27/02/26.
//

import SwiftUI
import CoreData

// --- HELPER STRUCT: Unifies all types of events (Birth, Photo Added, etc.) ---
struct TimelineEvent: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
    let description: String
    let type: String // e.g., "birth", "death", "media_photo", "partner_joined"
    let relatedPersonName: String? // Name of the person the event belongs to
    let color: Color

    // Static initializer to easily create events from different sources
    static func fromPerson(_ person: Person, color: Color) -> [TimelineEvent] {
        var events: [TimelineEvent] = []
        
        // 1. Birth Event
        if let dob = person.dateOfBirth {
            events.append(TimelineEvent(
                date: dob,
                title: "Birth",
                description: "\(person.name ?? "Someone") was born.",
                type: "birth",
                relatedPersonName: person.name,
                color: color
            ))
        }
        
        // 2. Death Event (Optional)
        if let dod = person.dateOfDeath {
            events.append(TimelineEvent(
                date: dod,
                title: "Passing",
                description: "\(person.name ?? "Someone") passed away.",
                type: "death",
                relatedPersonName: person.name,
                color: .secondary // Use grey for death events
            ))
        }
        
        // 3. Media/Memory Events (We only track the date it was added for now)
        (person.memories as? Set<Memory> ?? []).forEach { memory in
            events.append(TimelineEvent(
                date: memory.dateAdded ?? Date.distantFuture,
                title: "Added \(memory.type ?? "Memory")",
                description: "A \(memory.type ?? "media item") was added to the archive.",
                type: "media_\(memory.type ?? "file")",
                relatedPersonName: person.name,
                color: .orange // Color for archive updates
            ))
        }
        
        return events
    }
}


struct TimelineView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var genManager: GenerationManager // Access color manager
    
    // Fetch all people needed for the timeline
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Person.name, ascending: true)],
        animation: .default
    )
    private var people: FetchedResults<Person>
    
    @State private var allEvents: [TimelineEvent] = []
    
    // Use a dictionary to group events by Year/Decade for clear dividers
    @State private var eventsByYear: [Int: [TimelineEvent]] = [:]

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedYears, id: \.self) { year in
                    Section(header: YearDivider(year: year)) {
                        ForEach(eventsByYear[year] ?? []) { event in
                            EventRowView(event: event)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Memory Timeline")
        }
        .onAppear {
            generateTimeline()
        }
        .onChange(of: people.count) { _ in
            generateTimeline() // Regenerate if people are added/deleted in the Tree View
        }
    }
    
    // --- CORE LOGIC ---
    
    private func generateTimeline() {
        var combinedEvents: [TimelineEvent] = []
        
        for person in people {
            let personColor = genManager.colorForGeneration(person.generation)
            let events = TimelineEvent.fromPerson(person, color: personColor)
            combinedEvents.append(contentsOf: events)
        }
        
        // Sort chronologically (newest event first is usually best for an archive)
        let sorted = combinedEvents.sorted { $0.date > $1.date }
        
        // Group by Year for Section Headers
        self.eventsByYear = groupEventsByYear(sorted)
    }
    
    private func groupEventsByYear(_ events: [TimelineEvent]) -> [Int: [TimelineEvent]] {
        var groups: [Int: [TimelineEvent]] = [:]
        for event in events {
            let year = Calendar.current.component(.year, from: event.date)
            groups[year, default: []].append(event)
        }
        return groups
    }
    
    private var sortedYears: [Int] {
        eventsByYear.keys.sorted { $0 > $1 } // Display most recent year first
    }
}

// --- UI Components for the Timeline ---

struct YearDivider: View {
    let year: Int
    var body: some View {
        HStack {
            Text("\(year)")
                .font(.title2).bold()
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

struct EventRowView: View {
    let event: TimelineEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Timeline Dot/Marker
            Circle()
                .fill(event.color)
                .frame(width: 14, height: 14)
                .padding(.top, 6) // Align center with text line height
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(event.color)
                
                Text(event.description)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(event.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}
