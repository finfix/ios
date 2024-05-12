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
    
    // View states
    var shouldDisableUI = false
    var shouldShowProgress = false
    var shouldShowPickerAccountFrom = false
    var shouldShowPickerAccountTo = false
    var shouldShowDatePicker = false
    
    // Data
    var accounts: [Account] = []
    var tags: [Tag] = []
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
        tags = try await service.getTags(accountGroup: accountGroup)
    }
    
    func createTransaction() async throws {
        try await service.createTransaction(currentTransaction)
    }
    
    func updateTransaction() async throws {
        try await service.updateTransaction(newTransaction: currentTransaction, oldTransaction: oldTransaction)
    }
}
