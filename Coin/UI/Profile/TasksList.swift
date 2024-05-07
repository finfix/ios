//
//  TasksList.swift
//  Coin
//
//  Created by Илья on 29.04.2024.
//

import SwiftUI

enum TasksListRoute: Hashable {
    case taskDetails(SyncTask)
}

struct TasksList: View {
    
    @State private var vm = TasksListViewModel()
    @Environment (AlertManager.self) private var alert
    @Binding var path: NavigationPath
    
    var body: some View {
        List {
            Section(footer: Text("Количество: \(vm.tasks.count)")) {
                ForEach(vm.tasks) { task in
                    NavigationLink(value: TasksListRoute.taskDetails(task)) {
                        Text("\(task.id). \(task.actionName)")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .task{
            do {
                try await vm.load()
            } catch {
                alert(error)
            }
        }
    }
}

#Preview {
    TasksList(path: .constant(NavigationPath()))
}
