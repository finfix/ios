//
//  BudgetsListViewModel.swift
//  Coin
//
//  Created by Илья on 26.03.2024.
//

import Foundation

@Observable
class BudgetsListViewModel {
    private let service = Service.shared
    
    var accounts: [Account] = []
    
    var accountGroup = AccountGroup()
    
    func load(accountGroup: AccountGroup) async throws {
        let tmpAccounts = try await service.getAccounts(
            accountGroup: accountGroup,
            visible: true,
            types: [.expense]
        )
        accounts = Account.groupAccounts(tmpAccounts).filter { $0.showingBudgetAmount != 0 }
    }
}
