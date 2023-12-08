//
//  Budgets.swift
//  Coin
//
//  Created by Илья on 16.10.2023.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "Coin", category: "BudgetList")

struct BudgetsList: View {
    
    @AppStorage("accountGroupID") var selectedAccountsGroupID: Int = 0
    @Query(sort: [
        SortDescriptor(\Account.serialNumber)
    ]) var accounts: [Account]
        
    func groupAccounts() -> [Account] {
        logger.info("Группируем счета")
        let accounts = accounts.filter {
            $0.visible &&
            $0.accountGroup?.id == UInt32(selectedAccountsGroupID) &&
            $0.type == .expense
        }
        return Account.groupAccounts(accounts).filter { $0.showingBudget != 0 }
    }
        
    var body: some View {
        let groupedAccounts = groupAccounts()
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
        .modelContainer(previewContainer)
}
