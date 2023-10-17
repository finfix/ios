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
        modelData.accountsGrouped.filter { account in
            account.type == "expense"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(filteredAccounts) { account in
                    BudgetRow(account: account)
                }
            }
        }
        .onAppear(perform: modelData.getAccountsGrouped)
    }
}

#Preview {
    BudgetsList()
}
