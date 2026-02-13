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
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
