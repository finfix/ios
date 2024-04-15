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
        
    @Environment (AlertManager.self) private var alert
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
            do {
                try vm.load()
            } catch {
                alert(error)
            }
        }
    }
}

#Preview {
    BudgetsList(accountGroup: AccountGroup(id: 1))
}
