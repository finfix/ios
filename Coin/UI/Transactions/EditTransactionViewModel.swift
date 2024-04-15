//
//  EditTransactionViewModel.swift
//  Coin
//
//  Created by Илья on 26.03.2024.
//

import Foundation
import SwiftUI

@Observable
class EditTransactionViewModel {
    private let service = Service.shared
    
    var accounts: [Account] = []
    
    var currentTransaction = Transaction()
    var oldTransaction = Transaction()
    var accountGroup = AccountGroup()
    
    var mode: mode
    
    var intercurrency: Bool {
        currentTransaction.accountFrom.currency != currentTransaction.accountTo.currency
    }
    
    init(
        currentTransaction: Transaction,
        oldTransaction: Transaction = Transaction(),
        accountGroup: AccountGroup,
        mode: mode
    ) {
        self.currentTransaction = currentTransaction
        self.oldTransaction = oldTransaction
        self.accountGroup = accountGroup
        self.mode = mode
    }
            
    func load() async throws {
        accounts = try await service.getAccounts(accountGroup: accountGroup)
        if mode == .create {
            let accountFrom = getAccountsForShowingInCreate(accounts: accounts, position: .up, transactionType: currentTransaction.type, excludedAccount: nil).first ?? Account()
            currentTransaction.accountFrom = accountFrom
            currentTransaction.accountTo = getAccountsForShowingInCreate(accounts: accounts, position: .down, transactionType: currentTransaction.type, excludedAccount: accountFrom).first ?? Account()
        }
    }
    
    func createTransaction() async throws {
        try await service.createTransaction(currentTransaction)
    }
    
    func updateTransaction() async throws {
        try await service.updateTransaction(newTransaction: currentTransaction, oldTransaction: oldTransaction)
    }
}
