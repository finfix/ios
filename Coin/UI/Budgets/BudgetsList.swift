//
//  Budgets.swift
//  Coin
//
//  Created by Илья on 16.10.2023.
//

import SwiftUI

struct BudgetsList: View {
    
    @Environment(ModelData.self) var modelData
    
    var filteredAccounts: [Account] {
        modelData.accounts.filter {
            ($0.accountGroupID == modelData.selectedAccountsGroupID) &&
            $0.visible &&
            !$0.isChild &&
            $0.type == .expense &&
            $0.budget != 0 }
    }
    
    var body: some View {
        ScrollView {
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
