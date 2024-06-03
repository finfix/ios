//
//  ProfileTab.swift
//  Coin
//
//  Created by Илья on 02.06.2024.
//

import SwiftUI

struct ProfileTab: View {
    
    @State var path = PathSharedState()
    @Environment(AccountGroupSharedState.self) var selectedAccountGroup
    
    var body: some View {
        NavigationStack(path: $path.path) {
            Profile()
                .navigationDestination(for: ProfileViews.self) { screen in
                    switch screen {
                    case .hidedAccounts: HidedAccountsList()
                    case .currencyConverter: CurrencyConverter()
                    case .settings: Settings()
                    case .accountGroupsList: AccountGroupList()
                    }
                }
                .navigationDestination(for: AccountGroupListRoute.self) { screen in
                    switch screen {
                    case .createAccountGroup: EditAccountGroup()
                    case .updateAccountGroup(let accountGroup): EditAccountGroup(accountGroup)
                    }
                }
                .navigationDestination(for: AccountCircleItemRoute.self) { screen in
                    switch screen {
                    case .accountTransactions(let account): TransactionsView(account: account)
                    case .editAccount(let account): EditAccount(account, selectedAccountGroup: selectedAccountGroup.selectedAccountGroup, isHiddenView: false)
                    }
                }
                .navigationDestination(for: TransactionsListRoute.self) { screen in
                    switch screen {
                    case .editTransaction(let transaction): EditTransaction(transaction)
                    }
                }
        }
        .environment(path)
    }
}

#Preview {
    ProfileTab()
}
