//
//  EditAccountGroup.swift
//  Coin
//
//  Created by Илья on 23.05.2024.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "EditAccountGroup")

struct EditAccountGroup: View {
    
    @Environment (\.dismiss) private var dismiss
    @State private var vm: EditAccountGroupViewModel
    @Environment (AlertManager.self) private var alert
    
    @State var shouldDisableUI = false
    @State var shouldShowProgress = false
    
    init(_ accountGroup: AccountGroup, path: Binding<NavigationPath>) {
        vm = EditAccountGroupViewModel(
            currentAccountGroup: accountGroup,
            oldAccountGroup: accountGroup,
            mode: .update
        )
    }
    
    init(path: Binding<NavigationPath>) {
        vm = EditAccountGroupViewModel(
            currentAccountGroup: AccountGroup(),
            mode: .create
        )
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Название", text: $vm.currentAccountGroup.name)
            }
            Section {
                Picker("Валюта", selection: $vm.currentAccountGroup.currency) {
                    ForEach(vm.currencies) { currency in
                        Text(currency.name)
                            .tag(currency)
                    }
                }
            }
            Section {
                Button {
                    Task {
                        shouldDisableUI = true
                        shouldShowProgress = true
                        defer {
                            shouldDisableUI = false
                            shouldShowProgress = false
                        }
                        
                        do {
                            switch vm.mode {
                            case .create: try await vm.createAccountGroup()
                            case .update: try await vm.updateAccountGroup()
                            }
                        } catch {
                            alert(error)
                            return
                        }
                        
                        dismiss()
                    }
                } label: {
                    if shouldShowProgress {
                        ProgressView()
                    } else {
                        Text("Сохранить")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            if vm.currentAccountGroup.id != 0 {
                Section(footer:
                    VStack(alignment: .leading) {
                        Text("ID: \(vm.currentAccountGroup.id)")
                        Text("Дата и время создания: \(vm.currentAccountGroup.datetimeCreate, format: .dateTime)")
                    }
                ) {}
            }
        }
        .toolbar(content: {
            ToolbarItem {
                Button(role: .destructive) {
                    Task {
                        do {
                            try await vm.deleteAccountGroup()
                        } catch {
                            alert(error)
                            return
                        }
                        
                        dismiss()
                    }
                } label: {
                    if shouldShowProgress {
                        ProgressView()
                    } else {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        })
        .task {
            do {
                try await vm.load()
            } catch {
                alert(error)
            }
        }
        .disabled(shouldDisableUI)
    }
}

#Preview {
    EditAccountGroup(AccountGroup(), path: .constant(NavigationPath()))
        .environment(AlertManager(handle: {_ in }))
}
