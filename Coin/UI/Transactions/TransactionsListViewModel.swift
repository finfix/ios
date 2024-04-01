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
    var groupedTransactionByDate: [Date: [Transaction]] {
        Dictionary(grouping: transactions, by: { $0.dateTransaction })
    }
    
    var page = 0
    var transactionsCancelled = false
    
    func load(refresh: Bool) {
        do {
            if refresh {
                page = 0
                transactionsCancelled = false
            }
            
            let newTransactions = try service.getTransactions(page: page)
            
            if newTransactions.isEmpty {
                transactionsCancelled = true
            }
            
            if refresh {
                transactions = newTransactions
            } else {
                transactions.append(contentsOf: newTransactions)
            }

            page += 1
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
