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
            let firstAccountGroup = vm.load()
            if selectedAccountGroup.id == 0 {
                selectedAccountGroup = firstAccountGroup
            }
        }
    }
}

#Preview {
    AccountGroupSelector(selectedAccountGroup: .constant(AccountGroup()))
}
