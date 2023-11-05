//
//  Budgets.swift
//  Coin
//
//  Created by Илья on 16.10.2023.
//

import SwiftUI
import SwiftData

struct BudgetsList: View {
        
    @AppStorage("accountGroupIndex") var selectedAccountsGroupIndex: Int = 0
    @Query var accounts: [Account]
    @Query var accountGroups: [AccountGroup]
    
    var filteredAccounts: [Account] {
        accounts.filter {
            ($0.accountGroupID == accountGroups[selectedAccountsGroupIndex].id) &&
            $0.visible &&
            $0.type == .expense &&
            $0.showingBudget != 0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Header()
                if accountGroups.count > 1 {
                    AccountsGroupSelector()
                }
            }
            VStack {
                ForEach(filteredAccounts) { account in
                    BudgetRow(account: account)
                }
            }
        }
    }
}

#Preview {
    BudgetsList()
}
