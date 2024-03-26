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
    
    func load() {
        do {
            transactions.append(contentsOf: try service.getFullTransactionsPage(page: page))
        } catch {
            showErrorAlert("\(error)")
        }
    }
}
