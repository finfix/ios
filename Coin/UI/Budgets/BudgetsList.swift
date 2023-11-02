//
//  Budgets.swift
//  Coin
//
//  Created by Илья on 16.10.2023.
//

import SwiftUI

struct BudgetsList: View {
    
    @Environment(ModelData.self) var modelData
    
    @AppStorage("accountGroupIndex") var selectedAccountsGroupIndex: Int = 0
    
    var filteredAccounts: [Account] {
        modelData.accounts.filter {
            ($0.accountGroupID == modelData.accountGroups[selectedAccountsGroupIndex].id) &&
            $0.visible &&
            !$0.isChild &&
            $0.type == .expense &&
            $0.budget != 0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Header()
                if modelData.accountGroups.count > 1 {
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
