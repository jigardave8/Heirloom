//
//  CanvasHelpers.swift
//  Heirloom
//
//  Created by BitDegree on 21/02/26.
//

import SwiftUI
import CoreData

// 1. Draggable Node
struct DraggablePersonNode: View {
    @ObservedObject var person: Person
    
    // Config properties
    var scale: CGFloat
    var color: Color
    var isConnecting: Bool
    var isSelectedSource: Bool // Is this the parent we are trying to link from?
    
    // Callbacks
    var onSelect: () -> Void
    var onDelete: () -> Void // <--- Added for deletion logic
    
    @Environment(\.managedObjectContext) var viewContext
    
    // Internal State
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        VStack(spacing: 0) {
            // Icon
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(isSelectedSource ? .white : color)
                .background(Circle().fill(Color.white))
            
            // Name
            Text(person.name ?? "Unknown")
                .font(.system(size: 10, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.9))
                .cornerRadius(4)
                .lineLimit(1)
                .offset(y: 4)
        }
        .frame(width: 80, height: 80)
        // Selection Styling
        .background(
            ZStack {
                Circle()
                    .fill(isSelectedSource ? Color.green : color.opacity(0.15))
                Circle()
                    .stroke(isSelectedSource ? Color.green : color, lineWidth: isSelectedSource ? 4 : 2)
            }
        )
        // Highlight/Glow if active source
        .shadow(color: isSelectedSource ? .green.opacity(0.5) : .clear, radius: 10)
        .scaleEffect(isSelectedSource ? 1.2 : 1.0)
        .animation(.spring(), value: isSelectedSource)
        
        // --- Position on Infinite Canvas ---
        .position(x: person.xPosition + dragOffset.width,
                  y: person.yPosition + dragOffset.height)
        
        // --- Interactions ---
        .onTapGesture {
            onSelect()
        }
        .contextMenu {
            // Context Menu for actions
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Person", systemImage: "trash")
            }
        }
        // Logic: Dragging is disabled when Linking
        .gesture(
            isConnecting ? nil : DragGesture()
                .onChanged { value in
                    self.dragOffset = CGSize(
                        width: value.translation.width / scale,
                        height: value.translation.height / scale
                    )
                }
                .onEnded { value in
                    person.xPosition += value.translation.width / scale
                    person.yPosition += value.translation.height / scale
                    self.dragOffset = .zero
                    try? viewContext.save()
                }
        )
    }
}

// 2. Bezier Connector
struct CurvedConnector: Shape {
    var start: CGPoint
    var end: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        
        // Professional S-Curve Algorithm
        let deltaX = abs(end.x - start.x) * 0.5
        let deltaY = abs(end.y - start.y) * 0.5
        // Using vertical hierarchy assumption (parent usually above)
        let control1 = CGPoint(x: start.x, y: start.y + deltaY)
        let control2 = CGPoint(x: end.x, y: end.y - deltaY)
        
        path.addCurve(to: end, control1: control1, control2: control2)
        return path
    }
}

// 3. Grid Background
struct GridPattern: Shape {
    let spacing: CGFloat = 50
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for x in stride(from: 0, to: rect.maxX, by: spacing) {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        for y in stride(from: 0, to: rect.maxY, by: spacing) {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        return path
    }
}
