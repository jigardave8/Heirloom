//
//  MediaRendererView.swift
//  Heirloom
//
//  Created by BitDegree on 27/02/26.
//
import SwiftUI
import CoreData
import AVKit

struct MediaRendererView: View {
    @ObservedObject var memory: Memory // Must be Observable for potential state changes
    
    @State private var isShowingFullScreen = false
    @State private var isAudioPlaying = false
    @State private var isVideoPlaying = false

    var body: some View {
        if let fileName = memory.fileName, !fileName.isEmpty {
            let fileURL = MediaManager.shared.getFileURL(fileName: fileName)
            
            switch memory.type {
            case "photo":
                // Assuming SavedImageView is accessible (from GalleryGridView logic)
                SavedImageView(fileName: fileName)
                    .onTapGesture { isShowingFullScreen = true }
                    .frame(width: 100, height: 100)
                    .clipped()
            
            case "video":
                Button("Play Video: \(memory.title ?? "Video")") {
                    isVideoPlaying = true
                }
                .frame(height: 100)
                .sheet(isPresented: $isVideoPlaying) {
                    VideoPlayerView(url: fileURL)
                }

            case "audio":
                AudioPlayerView(url: fileURL, isPlaying: $isAudioPlaying)
                    .frame(height: 100)
            
            case "pdf":
                Text("PDF: \(memory.title ?? "Document")")
                    .onTapGesture { isShowingFullScreen = true } // Link to PDF view in List

            default:
                Text("Unknown Type")
            }
        } else {
            Text("Memory Error")
        }
    }
}
