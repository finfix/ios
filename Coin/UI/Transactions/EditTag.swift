//
//  EditTag.swift
//  Coin
//
//  Created by Илья on 21.04.2024.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "EditTag")

struct EditTag: View {
    
    @Environment (\.dismiss) private var dismiss
    @State private var vm: EditTagViewModel
    @Environment (AlertManager.self) private var alert
    
    @State var shouldDisableUI = false
    @State var shouldShowProgress = false
    
    init(_ tag: Tag, path: Binding<NavigationPath>) {
        vm = EditTagViewModel(
            currentTag: tag,
            oldTag: tag,
            mode: .update
        )
    }
    
    init(selectedAccountGroup: AccountGroup, path: Binding<NavigationPath>) {
        vm = EditTagViewModel(
            currentTag: Tag(
                accountGroup: selectedAccountGroup
            ),
            mode: .create
        )
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Название", text: $vm.currentTag.name)
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
                            case .create: try await vm.createTag()
                            case .update: try await vm.updateTag()
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
            if vm.currentTag.id != 0 {
                Section(footer:
                    VStack(alignment: .leading) {
                        Text("ID: \(vm.currentTag.id)")
                        Text("Дата и время создания: \(vm.currentTag.datetimeCreate, format: .dateTime)")
                    }
                ) {}
            }
        }
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
    EditTag(Tag(), path: .constant(NavigationPath()))
        .environment(AlertManager(handle: {_ in }))
}
