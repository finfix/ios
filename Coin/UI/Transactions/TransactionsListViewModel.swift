//
//  TransactionsListViewModel.swift
//  Coin
//
//  Created by Илья on 25.03.2024.
//

import Foundation

@Observable
class TransactionsListViewModel {
    private let service = Service.shared
    
    var transactions: [Transaction] = []
    
    var page = 0
    var transactionsCancelled = false
    let pageSize = 100
    
    func load(
        refresh: Bool,
        filters: TransactionFilters
    ) async throws {
        var offset = 0
        var limit = 0
        
        if refresh {
            offset = 0
            limit = page * pageSize
        } else {
            offset = page * pageSize
            limit = pageSize
            page += 1
        }
        
        var accountIDs: [UInt32] = []
        if let account = filters.account {
            accountIDs = [account.id]
            for childAccount in account.childrenAccounts {
                accountIDs.append(childAccount.id)
            }
        }

        
        let transactions = try await service.getTransactions(
            limit: limit,
            offset: offset,
            dateFrom: filters.dateFrom,
            dateTo: filters.dateTo,
            searchText: filters.searchText,
            accountIDs: accountIDs,
            transactionType: filters.transactionType,
            currency: filters.currency
        )
        
        if transactions.isEmpty {
            transactionsCancelled = true
        }
        
        if refresh {
            self.transactions = transactions
        } else {
            self.transactions.append(contentsOf: transactions)
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) async throws {
        guard let index = transactions.firstIndex(of: transaction) else {
            throw ErrorModel(humanTextError: "Не смогли найти позицию транзакции №\(transaction.id) в массиве")
        }
        _ = transactions.remove(at: index)
        try await service.deleteTransaction(transaction)
    }
}
