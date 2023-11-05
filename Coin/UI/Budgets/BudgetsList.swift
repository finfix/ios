//
//  Budgets.swift
//  Coin
//
//  Created by Илья on 16.10.2023.
//

import SwiftUI
import SwiftData

struct BudgetsList: View {
        
    @AppStorage("accountGroupID") var selectedAccountsGroupID: Int = 0
    @Query var accounts: [Account]
    
    var filteredAccounts: [Account] {
        var tmp = accounts.filter {
            ($0.accountGroupID == selectedAccountsGroupID) &&
            $0.visible &&
            $0.type == .expense &&
            $0.showingBudget != 0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Header()
                AccountsGroupSelector()
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
