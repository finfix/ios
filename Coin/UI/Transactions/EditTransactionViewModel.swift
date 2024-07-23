//
//  EditTransactionViewModel.swift
//  Coin
//
//  Created by Илья on 26.03.2024.
//

import Foundation
import SwiftUI
import PhotosUI

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
    var amountFrom: Double = 0 {
        didSet {
            currentTransaction.amountFrom = Decimal(floatLiteral: amountFrom).round(factor: 7)
        }
    }
    var amountTo: Double = 0 {
        didSet {
            currentTransaction.amountTo = Decimal(floatLiteral: amountTo).round(factor: 7)
        }
    }
    var oldTransaction = Transaction()
    var accountGroup = AccountGroup()
    var mode: mode
    var imageSelection: PhotosPickerItem? = nil
    var transactionImage: UIImage? = nil
    
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
        self.amountFrom = currentTransaction.amountFrom.doubleValue
        self.amountTo = currentTransaction.amountTo.doubleValue
    }
            
    func load() async throws {
        accounts = try await service.getAccounts(accountGroup: accountGroup)
        tags = try await service.getTags(accountGroup: accountGroup)
    }
    
    func save() async throws {
        shouldDisableUI = true
        shouldShowProgress = true
        defer {
            shouldDisableUI = false
            shouldShowProgress = false
        }
        
        switch mode {
        case .create: try await service.createTransaction(currentTransaction)
        case .update: try await service.updateTransaction(newTransaction: currentTransaction, oldTransaction: oldTransaction)
        }
    }
}
