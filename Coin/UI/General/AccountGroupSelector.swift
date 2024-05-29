//
//  SelectAccountGroup.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "account group selector")

struct AccountGroupSelector: View {
    
    @Environment (AlertManager.self) private var alert
    @State private var vm = AccountGroupSelectorViewModel()
    @Environment(AccountGroupSharedState.self) var selectedAccountGroup
    @AppStorage("selectedAccountGroupID") var selectedAccountGroupID: Int = 0
    var pickerName: String = ""
    
    var body: some View {
        @Bindable var selectedAccountGroup = selectedAccountGroup
        Picker(pickerName, selection: $selectedAccountGroup.selectedAccountGroup) {
            ForEach(vm.accountGroups) { accountGroup in
                Text(accountGroup.name)
                    .tag(accountGroup)
            }
        }
        .pickerStyle(.menu)
        .task {
            do {
                try await vm.load()
                if let selectedAccountGroup = vm.accountGroups.first(where: { $0.id == UInt32(selectedAccountGroupID) }) {
                    if selectedAccountGroup.currency != self.selectedAccountGroup.selectedAccountGroup.currency {
                        self.selectedAccountGroup.selectedAccountGroup = AccountGroup() // TODO: Поправить костыль
                        self.selectedAccountGroup.selectedAccountGroup = selectedAccountGroup
                    }
                    self.selectedAccountGroup.selectedAccountGroup = selectedAccountGroup
                } else {
                    self.selectedAccountGroup.selectedAccountGroup = vm.accountGroups.first ?? AccountGroup()
                }
            } catch {
                alert(error)
            }
        }
        .onChange(of: selectedAccountGroup.selectedAccountGroup) { _, newValue in
            selectedAccountGroupID = Int(newValue.id)
        }
    }
}

#Preview {
    AccountGroupSelector()
        .environment(AlertManager(handle: {_ in }))
}
