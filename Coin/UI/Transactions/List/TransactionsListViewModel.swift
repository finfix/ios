//
//  TransactionsListViewModel.swift
//  Coin
//
//  Created by Илья on 25.03.2024.
//

import Foundation
import Factory

@Observable
class TransactionsListViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var transactions: [Transaction] = []
    
    var page = 0
    let pageSize = 10000
    var user: User = User()
        
    @MainActor
    func load(filters: TransactionFilters) async throws {
        
        var accountIDs: [UInt32] = []
        for account in filters.accounts {
            accountIDs.append(account.id)
            for childAccount in account.childrenAccounts {
                accountIDs.append(childAccount.id)
            }
        }
        
        var accountGroupIDs: [UInt32] = []
        for accountGroup in filters.accountGroups {
            accountGroupIDs.append(accountGroup.id)
        }
        
        var tagIDs: [UInt32] = []
        for tag in filters.tags {
            tagIDs.append(tag.id)
        }
        
        self.transactions = try await service.getTransactions(
            limit: 100,
            offset: 0,
            dateFrom: filters.dateFrom,
            dateTo: filters.dateTo,
            searchText: filters.searchText,
            accountIDs: accountIDs,
            transactionTypes: filters.transactionTypes,
            currencies: filters.currencies,
            tagsIDs: tagIDs,
            accountGroupIDs: accountGroupIDs
        )
                                
        self.user = try await service.getUsers()[0]
    }
        
    func deleteTransaction(_ transaction: Transaction) async throws {
        guard let index = transactions.firstIndex(of: transaction) else {
            throw ErrorModel(humanText: "Не смогли найти позицию транзакции №\(transaction.id) в массиве")
        }
        _ = transactions.remove(at: index)
        try await service.deleteTransaction(transaction)
    }
}
