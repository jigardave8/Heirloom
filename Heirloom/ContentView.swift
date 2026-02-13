//
//  ContentView.swift
//  Heirloom
//
//  Created by BitDegree on 13/02/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    // We do NOT need the 'Item' fetch request here.
    // The specific views (TreeCanvasView) handle their own data.

    var body: some View {
        // Point directly to our new Tree Component
        TreeCanvasView()
    }
}
