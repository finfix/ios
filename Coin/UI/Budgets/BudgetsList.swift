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
    var accountGroup: AccountGroup
    @State private var vm = BudgetsListViewModel()
        
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
                try await vm.load(accountGroup: accountGroup)
            } catch {
                alert(error)
            }
        }
        .onChange(of: accountGroup) { _, newValue in
            Task {
                do {
                    try await vm.load(accountGroup: newValue)
                } catch {
                    alert(error)
                }
            }
        }
    }
}

#Preview {
    BudgetsList(accountGroup: AccountGroup(id: 1))
}
