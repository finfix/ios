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
    
    private var accountGroup = AccountGroup()
    
    init(accountGroup: AccountGroup) {
        self.accountGroup = accountGroup
    }
        
    func load() throws {
        let tmpAccounts = try service.getAccounts(
            accountGroup: accountGroup,
            visible: true,
            types: [.expense]
        )
        accounts = Account.groupAccounts(tmpAccounts).filter { $0.showingBudgetAmount != 0 }
    }
}
