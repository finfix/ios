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
    
    func load(refresh: Bool) {
        do {
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
            
            let transactions = try service.getTransactions(limit: limit, offset: offset)
            
            if transactions.isEmpty {
                transactionsCancelled = true
            }
            
            if refresh {
                self.transactions = transactions
            } else {
                self.transactions.append(contentsOf: transactions)
            }

        } catch {
            showErrorAlert("\(error)")
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) async {
        do {
            guard let index = transactions.firstIndex(of: transaction) else {
                showErrorAlert("Не смогли найти позицию транзакции №\(transaction.id) в массиве")
                return
            }
            _ = transactions.remove(at: index)
            try await service.deleteTransaction(transaction)
        } catch {
            showErrorAlert("\(error)")
        }
    }
}
