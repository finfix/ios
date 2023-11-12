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
    
    var body: some View {
        BudgetsListSubView(accountGroupID: UInt32(selectedAccountsGroupID))
    }
}

struct BudgetsListSubView: View {
        
    @Query var accounts: [Account]
    @State var accountType: AccountType = .regular
    
    init(accountGroupID: UInt32) {
        debugLog("\nИнициализируем BudgetsListSubView")
        _accounts = Query(filter: #Predicate {
            $0.visible &&
//            $0.type.rawValue == accountType.rawValue &&
            $0.accountGroupID == accountGroupID })
    }
    
    var groupedAccounts: [Account] {
        groupAccounts(accounts)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                QuickStatisticView()
                AccountGroupSelector()
            }
            VStack {
                ForEach(groupedAccounts) { account in
                    BudgetRow(account: account)
                }
            }
        }
    }
}

#Preview {
    BudgetsList()
}
