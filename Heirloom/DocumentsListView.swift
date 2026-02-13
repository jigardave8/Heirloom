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
    
    // File Importer State
    @State private var isImporting: Bool = false
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Books & Documents")
                    .font(.headline)
                Spacer()
                Button(action: { isImporting = true }) {
                    Label("Attach PDF", systemImage: "doc.badge.plus")
                }
            }
            .padding()
            
            // List of Documents
            List {
                ForEach(person.memoriesArray ?? []) { memory in
                    // Only show PDF/Document types
                    if memory.type == "pdf" {
                        NavigationLink(destination: PDFPreviewView(fileName: memory.fileName ?? "")) {
                            HStack {
                                Image(systemName: "book.closed.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading) {
                                    Text(memory.title ?? "Untitled Document")
                                        .font(.headline)
                                    Text(memory.dateAdded?.formatted(date: .abbreviated, time: .omitted) ?? "")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                .onDelete(perform: deleteMemory)
            }
        }
        // File Picker Configuration
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf], // Allow PDFs (can add .plainText, etc.)
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile: URL = try result.get().first else { return }
                
                // 1. Security Access (Sandboxed)
                if selectedFile.startAccessingSecurityScopedResource() {
                    defer { selectedFile.stopAccessingSecurityScopedResource() }
                    
                    // 2. Read Data
                    let fileData = try Data(contentsOf: selectedFile)
                    
                    // 3. Save using MediaManager
                    if let savedName = MediaManager.shared.saveMedia(data: fileData, extensionType: "pdf") {
                        
                        // 4. Save to CoreData
                        let newDoc = Memory(context: viewContext)
                        newDoc.id = UUID()
                        newDoc.dateAdded = Date()
                        newDoc.type = "pdf"
                        newDoc.title = selectedFile.lastPathComponent // "MyBook.pdf"
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
        withAnimation {
            offsets.map { (person.memoriesArray ?? [])[$0] }.forEach(viewContext.delete)
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
