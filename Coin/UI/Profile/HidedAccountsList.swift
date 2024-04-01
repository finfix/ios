//
//  HidedAccountsList.swift
//  Coin
//
//  Created by Илья on 27.10.2023.
//

import SwiftUI

struct HidedAccountsList: View {
    
    @Binding var selectedAccountGroup: AccountGroup
    var accounts: [Account] = []
    @State var accountType: AccountType = .regular
    @Binding var path: NavigationPath
    var filteredAccounts: [Account] {
        accounts.filter {
            $0.type == accountType &&
            $0.accountGroup == selectedAccountGroup &&
            !$0.visible
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            AccountGroupSelector(selectedAccountGroup: $selectedAccountGroup)
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {
                    ForEach(filteredAccounts) { account in
                        AccountCircleItem(account, path: $path, selectedAccountGroup: $selectedAccountGroup)
                    }
                }
            }
        }
        .navigationDestination(for: Account.self) { EditAccount($0) }
        .contentMargins(.horizontal, 10, for: .automatic)
        .toolbar {
            Picker("Тип счета", selection: $accountType) {
                ForEach(AccountType.allCases, id: \.self) { value in
                    Text(value.rawValue)
                        .tag(value)
                }
            }
        }
    }
}

#Preview {
    HidedAccountsList(selectedAccountGroup: .constant(AccountGroup()), path: .constant(NavigationPath()))
}
