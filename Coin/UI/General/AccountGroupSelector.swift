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
    @Binding var selectedAccountGroup: AccountGroup
    
    var body: some View {
        Picker("", selection: $selectedAccountGroup) {
            ForEach(vm.accountGroups) { accountGroup in
                Text(accountGroup.name)
                    .tag(accountGroup)
            }
        }
        .pickerStyle(.menu)
        .task {
            do {
                let firstAccountGroup = try await vm.load()
                if selectedAccountGroup.id == 0 {
                    selectedAccountGroup = firstAccountGroup
                }
            } catch {
                alert(error)
            }
        }
    }
}

#Preview {
    AccountGroupSelector(selectedAccountGroup: .constant(AccountGroup()))
}
