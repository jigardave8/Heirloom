//
//  HeirloomApp.swift
//  Heirloom
//
//  Created by BitDegree on 13/02/26.
//

import SwiftUI

@main
struct HeirloomApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView() // <-- NEW ROOT VIEW
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(GenerationManager.shared) // <--

        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TreeCanvasView()
                .tabItem {
                    Label("Tree", systemImage: "tree.fill")
                }
            
            TimelineView() // This is the new view we just built
                .tabItem {
                    Label("Timeline", systemImage: "clock.fill")
                }
        }
    }
}
