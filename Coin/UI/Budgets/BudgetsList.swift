//
//  Budgets.swift
//  Coin
//
//  Created by Илья on 16.10.2023.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "BudgetList")

struct BudgetsList: View {
        
    @State private var vm: BudgetsListViewModel
    
    init(accountGroup: AccountGroup) {
        vm = BudgetsListViewModel(accountGroup: accountGroup)
    }
        
    var body: some View {
        ScrollView {
            VStack {
                ForEach(vm.accounts) { account in
                    BudgetRow(account: account)
                }
            }
        }
        .navigationTitle("Бюджеты")
        .task {
            vm.load()
        }
    }
}

#Preview {
    BudgetsList(accountGroup: AccountGroup(id: 1))
}
