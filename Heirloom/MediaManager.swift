//
//  MediaManager.swift
//  Heirloom
//
//  Created by BitDegree on 13/02/26.
//

import Foundation
import UIKit

class MediaManager {
    static let shared = MediaManager()
    
    // Get the path to the Documents Directory
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // 1. Save Data (Image, PDF, Video data)
    func saveMedia(data: Data, extensionType: String) -> String? {
        let fileName = UUID().uuidString + ".\(extensionType)"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileName // Return this to save in CoreData
        } catch {
            print("Error saving file: \(error)")
            return nil
        }
    }
    
    // 2. Load Data
    func getFileURL(fileName: String) -> URL {
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    // 3. Delete Data
    func deleteMedia(fileName: String) {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
}

