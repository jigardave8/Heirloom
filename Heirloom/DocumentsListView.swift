//
//  DocumentsListView.swift
//  Heirloom
//
//  Created by BitDegree on 13/02/26.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct DocumentsListView: View {
    @ObservedObject var person: Person
    @Environment(\.managedObjectContext) var viewContext
    
    @State private var isImporting: Bool = false
    
    var body: some View {
        VStack {
           
            HStack {
                Text("Books & Documents")
                    .font(.headline)
                Spacer()
                Button(action: { isImporting = true }) {
                    Label("Attach PDF", systemImage: "doc.badge.plus")
                }
            }
            .padding()
            
            // --- UPDATED: LIST ONLY SHOWS TYPE 'pdf' ---
            List {
                ForEach((person.memories as? Set<Memory> ?? []).filter { $0.type == "pdf" }, id: \.self) { memory in
                    NavigationLink(destination: PDFPreviewView(fileName: memory.fileName ?? "")) {
                        HStack {
                            Image(systemName: "book.closed.fill").foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text(memory.title ?? "Untitled Document")
                                    .font(.headline)
                                Text(memory.dateAdded?.formatted(date: .abbreviated, time: .omitted) ?? "")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteMemory)
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile: URL = try result.get().first else { return }
                
                if selectedFile.startAccessingSecurityScopedResource() {
                    defer { selectedFile.stopAccessingSecurityScopedResource() }
                    
                    let fileData = try Data(contentsOf: selectedFile)
                    
                    // Save as PDF
                    if let savedName = MediaManager.shared.saveMedia(data: fileData, extensionType: "pdf") {
                        let newDoc = Memory(context: viewContext)
                        newDoc.id = UUID()
                        newDoc.dateAdded = Date()
                        newDoc.type = "pdf"
                        newDoc.title = selectedFile.lastPathComponent
                        newDoc.fileName = savedName
                        newDoc.person = person
                        
                        try? viewContext.save()
                    }
                }
            } catch {
                print("Error reading file: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteMemory(offsets: IndexSet) {
        // NOTE: Deleting the Memory CoreData object DOES NOT delete the file from the file system!
        // You should add a deletion step here that calls MediaManager.shared.deleteMedia(fileName: ...)
        
        withAnimation {
            offsets.map { (person.memories as? Set<Memory> ?? []).filter { $0.type == "pdf" }[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

// Simple PDF View Wrapper
import PDFKit

struct PDFPreviewView: UIViewRepresentable {
    let fileName: String

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        let url = MediaManager.shared.getFileURL(fileName: fileName)
        if let document = PDFDocument(url: url) {
            uiView.document = document
        }
    }
}
