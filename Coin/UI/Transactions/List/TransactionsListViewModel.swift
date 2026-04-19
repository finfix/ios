//
//  TransactionsListViewModel.swift
//  Coin
//
//  Created by Илья on 25.03.2024.
//

import Foundation
import Factory

struct TransactionItem: Identifiable {
    let id: UUID
    let index: Int
    let transaction: Transaction
    let isNewSection: Bool
}

@Observable
class TransactionsListViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var transactionItems: [TransactionItem] = []
    
    var page = 0
    let pageSize = 10000
    var user: User = User()
        
    @MainActor
    func load(filters: TransactionFilters) async throws {
        
        var accountIDs: [UUID] = []
        for account in filters.accounts {
            accountIDs.append(account.id)
            for childAccount in account.childrenAccounts {
                accountIDs.append(childAccount.id)
            }
        }
        
        let transactions = try await service.getTransactions(
            limit: 1000,
            offset: 0,
            dateFrom: filters.dateFrom,
            dateTo: filters.dateTo,
            searchText: filters.searchText,
            accountIDs: accountIDs,
            transactionTypes: filters.transactionTypes,
            currencies: filters.currencies,
            tagIDs: filters.tags.map(\.id),
            accountGroupIDs: filters.accountGroups.map(\.id)
        )
        
        self.transactionItems = transactions.enumerated().map({ index, transaction in
            
            var isNewSection = true
            if index > 0 {
                isNewSection = transactions[index].dateTransaction != transactions[index - 1].dateTransaction
            }
            
            return TransactionItem(id: transaction.id, index: index, transaction: transaction, isNewSection: isNewSection)
        })
                                
        self.user = try await service.getUsers()[0]
    }
        
    func deleteTransaction(_ transaction: Transaction) async throws {
        guard let index = transactionItems.firstIndex(where: { $0.id == transaction.id }) else {
            throw ErrorModel(humanText: "Не смогли найти позицию транзакции №\(transaction.id) в массиве")
        }
        _ = transactionItems.remove(at: index)
        try await service.deleteTransaction(transaction)
    }
}
