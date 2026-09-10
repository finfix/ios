//
//  TaskGraph.swift
//  Coin
//

import SwiftUI

struct TaskGraphNodeView: View {

    let task: SyncTask

    private var color: Color {
        if task.completed { return .green }
        if task.error != nil { return .red }
        return .accentColor
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(task.actionName)")
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            Text(task.id.uuidString.prefix(8))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.15))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color, lineWidth: 1.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
