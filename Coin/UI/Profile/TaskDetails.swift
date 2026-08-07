//
//  TaskDetails.swift
//  Coin
//
//  Created by Илья on 29.04.2024.
//

import SwiftUI

struct TaskDetails: View {

    @State private var vm: TasksDetailsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(PathSharedState.self) var path
    @Environment(AlertManager.self) private var alert
    @State private var isLoadingLink = false

    init(task: SyncTask) {
        self.vm = TasksDetailsViewModel(task: task)
    }

    private var canJumpToObject: Bool {
        switch vm.task.actionName {
        case .createTransaction, .updateTransaction,
             .createAccount, .updateAccount,
             .createTag, .updateTag,
             .createAccountGroup, .updateAccountGroup:
            return true
        case .deleteTransaction, .deleteAccount, .deleteTag, .deleteAccountGroup, .updateUser:
            return false
        }
    }

    var body: some View {
        Form {
            HStack {
                Spacer()
                CopyableIDText(id: vm.task.id.uuidString)
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
            if canJumpToObject {
                Section {
                    Button {
                        Task {
                            isLoadingLink = true
                            defer { isLoadingLink = false }
                            do {
                                if let route = try await vm.fetchLinkedObjectRoute() {
                                    path.path.append(route)
                                } else {
                                    alert.warn(title: "Не найдено", message: "Объект уже удалён или не найден")
                                }
                            } catch {
                                alert.error(error)
                            }
                        }
                    } label: {
                        HStack {
                            Text("Перейти к объекту")
                            if isLoadingLink {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isLoadingLink)
                }
            }
            Section(header: Text("Параметры")) {
                Text(String(data: vm.task.fieldsJSON, encoding: .utf8) ?? "NULL")
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
