//
//  VideoPlayerView.swift
//  Heirloom
//
//  Created by BitDegree on 27/02/26.
//

import SwiftUI
import AVKit // Still needed for AVPlayer

struct VideoPlayerView: View { // CHANGE: Made it a View instead of UIViewRepresentable
    let url: URL

    var body: some View {
        // Use SwiftUI's native VideoPlayer for simpler presentation
        VideoPlayer(player: AVPlayer(url: url))
            .ignoresSafeArea(.all) // Fill the sheet if presented modally
    }
}
// Remove all UIViewRepresentable conformance methods (makeUIView, updateUIView)
