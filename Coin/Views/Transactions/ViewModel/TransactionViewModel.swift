//
//  ViewModal.swift
//  Coin
//
//  Created by Илья on 14.10.2022.
//

import SwiftUI

class TransactionViewModel: ObservableObject {
    
    //MARK: - Vars
    @Published var transactions = [Transaction]()
    @Published var withoutBalancing = false
    @Published var transactionType = 0
    @Published var searchText = ""
    
    var types = ["consumption", "income", "balancing", "transfer"]
    
    var transactionsFiltered: [Transaction]  {
        
        var subfiltered = transactions
        
        if searchText != "" {
            subfiltered = subfiltered.filter { ($0.note ?? "").hasPrefix(searchText) }
        }
        
        if withoutBalancing {
            subfiltered = subfiltered.filter { !($0.accountFromID == 0) }
        }
        
        if transactionType != 0 {
            subfiltered = subfiltered.filter { $0.typeSignatura == types[transactionType] }
        }
        
        return subfiltered
    }
    
    //MARK: - Methods
    func getTransaction() {
        
        /// Убедимся, что у нас есть URL-адрес, прежде чем запускать следующую строку кода.
        TransactionAPI().GetTransaction { transactions in
            self.transactions = transactions
        }
    }
    
    func deleteTransaction(at offsets: IndexSet) {
        
        var id = 0
        
        for i in offsets.makeIterator() {
            id = transactionsFiltered[i].id
        }
        
        TransactionAPI().DeleteTransaction(id: id) {
            print("Удаление \(id) прошло успешно")
        }
        transactions.remove(atOffsets: offsets)
    }
}

