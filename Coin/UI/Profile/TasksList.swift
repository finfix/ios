//
//  TasksList.swift
//  Coin
//
//  Created by Илья on 29.04.2024.
//

import SwiftUI


struct TasksList: View {
    
    @State private var vm = TasksListViewModel()
    @Environment(AlertManager.self) private var alert
    @Environment(\.dismiss) private var dismiss
    @Environment(PathSharedState.self) var path
    
    var body: some View {
        List {
            Section {
                Toggle("Показать выполненные", isOn: $vm.showCompleted)
            }
            Section(footer: Text("Количество: \(vm.tasks.count)")) {
                ForEach(vm.tasks) { task in
                    NavigationLink(value: TasksListRoute.taskDetails(task)) {
                        Text("\(task.id). \(task.actionName)")
                            .foregroundStyle(task.completed ? .secondary : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .toolbar(content: {
            ToolbarItem {
                Button {
                    path.path.append(TasksListRoute.taskGraph)
                } label: {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                }
            }
            ToolbarItem {
                Button(role: .destructive) {
                    Task {
                        do {
                            try await vm.deleteAllTasks()
                        } catch {
                            alert.error(error)
                            return
                        }
                        dismiss()
                    }
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
            }
        })
        // ValueObservation вместо load()/.refreshable — экран сам обновляется на любой коммит в
        // syncTaskDB. .task(id: vm.showCompleted) — переподписка на новый запрос при смене
        // тумблера (перезапускает Task, отменяя предыдущую подписку).
        .task(id: vm.showCompleted) {
            do {
                for try await tasks in vm.observeTasks() {
                    withAnimation {
                        vm.tasks = tasks
                    }
                }
            } catch {
                alert.error(error)
            }
        }
    }
}

#Preview {
    TasksList()
}
