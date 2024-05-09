//
//  TaskDetails.swift
//  Coin
//
//  Created by Илья on 29.04.2024.
//

import SwiftUI

struct TaskDetails: View {
        
    @State private var vm: TasksDetailsViewModel
    @Environment (\.dismiss) private var dismiss
    
    init(task: SyncTask) {
        self.vm = TasksDetailsViewModel(task: task)
    }
    
    var body: some View {
        Form {
            HStack {
                Text("ID:")
                Spacer()
                Text("\(vm.task.id)")
            }
            HStack {
                Text("Название действия:")
                Spacer()
                Text("\(vm.task.actionName)")
            }
            HStack {
                Text("Количество попыток:")
                Spacer()
                Text("\(vm.task.tryCount)")
            }
            HStack {
                Text("Локальный идентификатор объекта:")
                Spacer()
                Text("\(vm.task.localID)")
            }
            Section(header: Text("Параметры")) {
                ForEach(vm.task.fields) { field in
                    HStack {
                        Text(field.name)
                        Spacer()
                        Text(field.value ?? "NULL")
                    }
                }
            }
            Section(header: Text("Ошибка")) {
                HStack {
                    Text(vm.task.error ?? "")
                }
            }
        }
        .refreshable {
            Task {
                do {
                    try await vm.load()
                } catch {
                    dismiss()
                }
            }
        }
        .toolbar(content: {
            ToolbarItem {
                Button(role: .destructive) {
                    Task {
                        do {
                            try await vm.delete()
                        } catch {
                            
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
    }
}

#Preview {
    TaskDetails(task: SyncTask())
}
