//
//  GalleryGridView.swift
//  Heirloom
//
//  Created by BitDegree on 13/02/26.
//
import SwiftUI
import CoreData
import PhotosUI // <--- Essential for PhotosPickerItem

struct GalleryGridView: View {
    @ObservedObject var person: Person // Requires the Person Entity from CoreData
    @Environment(\.managedObjectContext) var viewContext
    
    // State for the Image Picker
    @State private var selectedPickerItem: PhotosPickerItem?
    
    var body: some View {
        VStack {
            // --- HEADER WITH ADD BUTTON ---
            HStack {
                Text("Memories")
                    .font(.headline)
                Spacer()
                
                // Photo Picker Button
                PhotosPicker(selection: $selectedPickerItem, matching: .images) {
                    Label("Add Photo", systemImage: "photo.on.rectangle.angled")
                }
                .onChange(of: selectedPickerItem) { newItem in
                    saveSelectedPhoto(newItem: newItem)
                }
            }
            .padding()

            // --- GRID VIEW ---
            // If the person has no memories, show a hint
            if let memories = person.memoriesArray, memories.isEmpty {
                ContentUnavailableView("No Photos Yet", systemImage: "photo")
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                        // Loop through saved memories
                        ForEach(person.memoriesArray ?? []) { memory in
                            if let fileName = memory.fileName {
                                // Display Image from Disk
                                SavedImageView(fileName: fileName)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // --- LOGIC TO SAVE PHOTO ---
    private func saveSelectedPhoto(newItem: PhotosPickerItem?) {
        guard let newItem = newItem else { return }
        
        Task {
            // 1. Convert Picker Item to Data
            if let data = try? await newItem.loadTransferable(type: Data.self) {
                
                // 2. Save Data to File System (Documents Directory)
                if let savedFileName = MediaManager.shared.saveMedia(data: data, extensionType: "jpg") {
                    
                    // 3. Save Reference to CoreData
                    await MainActor.run {
                        let newMemory = Memory(context: viewContext)
                        newMemory.id = UUID()
                        newMemory.dateAdded = Date()
                        newMemory.type = "photo" // Identify as photo
                        newMemory.fileName = savedFileName
                        newMemory.person = person // Connect to Parent
                        
                        try? viewContext.save()
                    }
                }
            }
        }
    }
}

// --- HELPER TO DISPLAY SAVED IMAGES ---
struct SavedImageView: View {
    let fileName: String
    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                    .overlay(ProgressView())
            }
        }
        .onAppear {
            loadFromFile()
        }
    }
    
    private func loadFromFile() {
        // Construct the full path
        let url = MediaManager.shared.getFileURL(fileName: fileName)
        // Load data on background thread to prevent UI freeze
        DispatchQueue.global(qos: .userInteractive).async {
            if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.uiImage = img
                }
            }
        }
    }
}

// --- EXTENSION FOR SAFETY ---
// This prevents crashes if the CoreData set is nil
extension Person {
    var memoriesArray: [Memory]? {
        let set = memories as? Set<Memory>
        return set?.sorted {
            $0.dateAdded ?? Date() > $1.dateAdded ?? Date()
        }
    }
}
