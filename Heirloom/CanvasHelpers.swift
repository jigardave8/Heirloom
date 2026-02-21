//
//  CanvasHelpers.swift
//  Heirloom
//
//  Created by BitDegree on 21/02/26.
//

import SwiftUI

// 1. The Draggable Card
struct DraggablePersonNode: View {
    @ObservedObject var person: Person
    var scale: CGFloat
    var color: Color
    var onSelect: () -> Void
    @Environment(\.managedObjectContext) var viewContext

    // Local gesture state
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        VStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(color)
            
            Text(person.name ?? "Unknown")
                .font(.caption)
                .bold()
                .padding(4)
                .background(Color.white.opacity(0.8))
                .cornerRadius(4)
        }
        .frame(width: 100, height: 80)
        .background(color.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color, lineWidth: 2)
        )
        // Position Logic
        .position(x: person.xPosition + dragOffset.width,
                  y: person.yPosition + dragOffset.height)
        .onTapGesture {
            onSelect()
        }
        // Independent Drag Logic
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Adjust translation by scale to keep movement 1:1 with finger
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

// 2. Curved Lines (Bezier)
struct CurvedConnector: Shape {
    var start: CGPoint
    var end: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        
        // Create a professional 'S' curve
        let deltaY = abs(end.y - start.y)
        let control1 = CGPoint(x: start.x, y: start.y + deltaY * 0.5)
        let control2 = CGPoint(x: end.x, y: end.y - deltaY * 0.5)
        
        path.addCurve(to: end, control1: control1, control2: control2)
        return path
    }
}

// 3. Grid Pattern Background
struct GridPattern: Shape {
    let spacing: CGFloat = 50
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Draw Vertical Lines
        for x in stride(from: 0, to: rect.maxX, by: spacing) {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        // Draw Horizontal Lines
        for y in stride(from: 0, to: rect.maxY, by: spacing) {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        return path
    }
}
