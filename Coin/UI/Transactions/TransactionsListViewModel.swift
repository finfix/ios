//
//  TransactionsListViewModel.swift
//  Coin
//
//  Created by Илья on 25.03.2024.
//

import Foundation
import Combine

@Observable
class TransactionsListViewModel {
    private let service = Service.shared
    
    private var transactions: [Transaction] = []
    var groupedTransactionByDate: [Date: [Transaction]] = [:]
    
    var page = 0
    var transactionsCancelled = false
    
    private var disposeBag: Set<AnyCancellable> = []
    
    init() {
        service.changes.sink { [weak self] change in
            self?.load(refresh: true)
        }
        .store(in: &disposeBag)
    }
    
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
            
            groupedTransactionByDate = Dictionary(grouping: transactions, by: { $0.dateTransaction })
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
