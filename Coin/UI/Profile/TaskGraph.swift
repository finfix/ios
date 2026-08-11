//
//  TaskGraph.swift
//  Coin
//

import SwiftUI

struct TaskGraph: View {

    @State private var vm = TaskGraphViewModel()
    @Environment(AlertManager.self) private var alert
    @Environment(PathSharedState.self) var path

    private let nodeWidth: CGFloat = 150
    private let nodeHeight: CGFloat = 56
    private let columnSpacing: CGFloat = 70
    private let rowSpacing: CGFloat = 24
    private let padding: CGFloat = 24

    private var columns: [[TaskGraphViewModel.Node]] {
        let nodes = vm.nodes
        guard !nodes.isEmpty else { return [] }
        let maxLayer = nodes.map(\.layer).max() ?? 0
        var result: [[TaskGraphViewModel.Node]] = Array(repeating: [], count: maxLayer + 1)
        for node in nodes {
            result[node.layer].append(node)
        }
        return result
    }

    private var positions: [UUID: CGPoint] {
        var result: [UUID: CGPoint] = [:]
        for (columnIndex, column) in columns.enumerated() {
            let x = CGFloat(columnIndex) * (nodeWidth + columnSpacing) + nodeWidth / 2
            for (rowIndex, node) in column.enumerated() {
                let y = CGFloat(rowIndex) * (nodeHeight + rowSpacing) + nodeHeight / 2
                result[node.id] = CGPoint(x: x, y: y)
            }
        }
        return result
    }

    private var contentSize: CGSize {
        let cols = columns
        let width = CGFloat(cols.count) * (nodeWidth + columnSpacing)
        let maxRows = cols.map(\.count).max() ?? 0
        let height = CGFloat(maxRows) * (nodeHeight + rowSpacing)
        return CGSize(width: max(width, 1), height: max(height, 1))
    }

    var body: some View {
        VStack(spacing: 0) {
            Toggle("Показать выполненные", isOn: $vm.showCompleted)
                .padding()
                .onChange(of: vm.showCompleted) {
                    Task {
                        do {
                            try await vm.load()
                        } catch {
                            alert.error(error)
                        }
                    }
                }
            Divider()

            if vm.nodes.isEmpty {
                Spacer()
                Text("Нет задач")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                let pos = positions
                let size = contentSize
                ScrollView([.horizontal, .vertical]) {
                    ZStack(alignment: .topLeading) {
                        Canvas { context, _ in
                            for edge in vm.edges {
                                guard let from = pos[edge.from], let to = pos[edge.to] else { continue }
                                var linePath = Path()
                                linePath.move(to: CGPoint(x: from.x + nodeWidth / 2, y: from.y))
                                linePath.addLine(to: CGPoint(x: to.x - nodeWidth / 2, y: to.y))
                                context.stroke(linePath, with: .color(.secondary.opacity(0.5)), lineWidth: 1.5)
                            }
                        }
                        .frame(width: size.width, height: size.height)

                        ForEach(vm.nodes) { node in
                            if let p = pos[node.id] {
                                TaskGraphNodeView(task: node.task)
                                    .frame(width: nodeWidth, height: nodeHeight)
                                    .position(p)
                                    .onTapGesture {
                                        path.path.append(TasksListRoute.taskDetails(node.task))
                                    }
                            }
                        }
                    }
                    .frame(width: size.width, height: size.height)
                    .padding(padding)
                }
            }
        }
        .navigationTitle("Граф зависимостей")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                try await vm.load()
            } catch {
                alert.error(error)
            }
        }
    }
}

private struct TaskGraphNodeView: View {

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

#Preview {
    TaskGraph()
}
