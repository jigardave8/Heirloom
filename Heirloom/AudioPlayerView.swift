//
//  AudioPlayerView.swift
//  Heirloom
//
//  Created by BitDegree on 27/02/26.
//

import SwiftUI
import AVKit

struct AudioPlayerView: UIViewRepresentable {
    let url: URL
    @Binding var isPlaying: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            context.coordinator.player = player
        } catch {
            print("Audio playback failed: \(error)")
        }
        
        let button = UIButton(type: .system)
        button.setTitle("Play/Pause Audio", for: .normal)
        button.addTarget(context.coordinator, action: #selector(Coordinator.togglePlayPause), for: .touchUpInside)
        view.addSubview(button)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if isPlaying {
            context.coordinator.player?.play()
        } else {
            context.coordinator.player?.pause()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self) // <--- CHANGE: Remove 'parent:' label here
    }

    class Coordinator: NSObject {
        var parent: AudioPlayerView
        var player: AVAudioPlayer?

        // NOTE: Initialize correctly in the init:
          init(_ parent: AudioPlayerView) { // <--- ENSURE 'parent:' is NOT in the signature
              self.parent = parent
          }
        
        @objc func togglePlayPause() {
            if player?.isPlaying == true {
                player?.pause()
                parent.isPlaying = false
            } else {
                player?.currentTime = 0
                player?.play()
                parent.isPlaying = true
            }
        }
        
        deinit {
            player?.stop()
        }
    }
}
