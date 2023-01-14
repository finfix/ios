//
//  ViewModal.swift
//  Coin
//
//  Created by Илья on 14.10.2022.
//

import SwiftUI
import Combine

struct ForChart {
    var date: Date
    var sum: Double
}

class TransactionViewModel: ObservableObject {
    
    //MARK: - Vars
    @Published var transactions = [Transaction]()
    
    var accountsMap: [Int: Account] {
        var accountsMap = Dictionary(uniqueKeysWithValues: accounts.map{ ($0.id, $0) })
        return accountsMap
    }
    
    @Published var accounts = [Account]()
    
    var transactionByDate: [Date : [Transaction]] {
        Dictionary(grouping: transactionsFiltered, by: { $0.dateTransaction })
    }
    
    @Published var withoutBalancing = false
    @Published var transactionType = 0
    @Published var searchText = ""
    
    @Published var d = false
    @Published var accountFromID = 0
    @Published var accountToID = 0
    @Published var amountFrom: String = ""
    @Published var amountTo: String = ""
    @Published var selectedType: Int = 0
    @Published var note = ""
    @Published var date = Date()
    
    @Published var appSettings = AppSettings()
    
    var types = ["consumption", "income", "balancing", "transfer"]
    
    var transactionsFiltered: [Transaction]  {
        
        var subfiltered = transactions
        
        if searchText != "" {
            subfiltered = subfiltered.filter { ($0.note ?? "").contains(searchText) }
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
    // Получаем транзакции
    func getTransaction(_ settings: AppSettings) {
        TransactionAPI().GetTransactions() { response, error in
            if let err = error {
                settings.showErrorAlert(error: err)
            } else if let response = response {
                self.transactions = response
            }
        }
    }
    
    // Получаем счета
    func getAccount(_ settings: AppSettings) {
        AccountAPI().GetAccounts { model, error in
            if let err = error {
                settings.showErrorAlert(error: err)
            } else if let response = model {
                self.accounts = response
            }
        }
    }
    
    func deleteTransaction(at offsets: IndexSet, _ settings: AppSettings) {
        
        var id = 0
        
        for i in offsets.makeIterator() {
            id = transactionsFiltered[i].id
        }
        
        TransactionAPI().DeleteTransaction(id: id) { error in
            
            if let err = error {
                settings.showErrorAlert(error: err)
            } else {
                self.transactions.remove(atOffsets: offsets)
            }
        }
    }
    
    func createTransaction(_ settings: AppSettings, isOpeningFrame: Binding<Bool>) {
        let format = DateFormatter()
        format.dateFormat = "YYYY-MM-dd"
        
        TransactionAPI().CreateTransaction(req: CreateTransactionRequest(accountFromID: Int(accountFromID) ?? 0, accountToID: Int(accountToID) ?? 0, amountFrom: Double(amountFrom) ?? 0, amountTo: (d ? Double(amountTo) : Double(amountFrom)) ?? 0, dateTransaction: format.string(from: date), note: note, type: types[selectedType], isExecuted: true)) { error in
            if let err = error {
                settings.showErrorAlert(error: err)
            }
        }
    }
}

