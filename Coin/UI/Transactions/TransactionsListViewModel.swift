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
    
    private var transactions: [Transaction] = []
    
    var page = 0
    var transactionsCancelled = false
    let pageSize = 100
    
    var groupedTransactionByDate: [Date: [Transaction]] = [:]
    
    func load(
        refresh: Bool,
        filters: TransactionFilters,
        selectedAccountGroup: AccountGroup
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
        
        regroup(selectedAccountGroup: selectedAccountGroup)
    }
    
    func regroup(selectedAccountGroup: AccountGroup) { // TODO: Убрать логику в бд, когда научусь делать JOIN'ы
        self.groupedTransactionByDate = Dictionary(grouping: transactions.filter { $0.accountFrom.accountGroup == selectedAccountGroup }, by: { $0.dateTransaction })
    }
    
    func deleteTransaction(_ transaction: Transaction, selectedAccountGroup: AccountGroup) async throws {
        guard let index = transactions.firstIndex(of: transaction) else {
            throw ErrorModel(humanTextError: "Не смогли найти позицию транзакции №\(transaction.id) в массиве")
        }
        _ = transactions.remove(at: index)
        regroup(selectedAccountGroup: selectedAccountGroup)
        try await service.deleteTransaction(transaction)
    }
}
