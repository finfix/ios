//
//  ViewModal.swift
//  Coin
//
//  Created by Илья on 14.10.2022.
//

import SwiftUI
import Combine

class TransactionViewModel: ObservableObject {
    
    @Environment(\.realm) var realm
    
    //MARK: - Vars
    @Published var withoutBalancing = false
    @Published var transactionType = 0
    @Published var searchText = ""
    
    @Published var d = false
    @Published var accountFromID = ""
    @Published var accountToID: String = ""
    @Published var amountFrom: String = ""
    @Published var amountTo: String = ""
    @Published var selectedType: Int = 0
    @Published var note = ""
    @Published var date = Date()
    
    @Published var appSettings = AppSettings()
    
    var types = ["consumption", "income", "balancing", "transfer"]
    
    //MARK: - Methods
    
    func getTransaction(_ settings: AppSettings) {
        
        // Если в базе данных нет транзакций
        if self.realm.objects(Transaction.self).isEmpty {
            
            // Делаем запрос на сервер
            TransactionAPI().GetTransactions() { response, error in
                if let err = error {
                    settings.showErrorAlert(error: err)
                } else if let response = response {
                    
                    // Добавляем все транзакции с сервера в базу данных
                    try? self.realm.write {
                        self.realm.add(response)
                    }
                }
            }
            
            // Если в базе данных есть транзакции
        } else {
            
            // Запрашиваем с сервера последние изменения
            UserAPI().GetChanges() { response, error in
                if let err = error {
                    settings.showErrorAlert(error: err)
                    
                    // И добавляем изменения в бд
                } else if let response = response {
                    
                    // Добавляем транзакции
                    if let transactions = response.created?.transactions {
                        try? self.realm.write {
                            self.realm.add(transactions)
                        }
                    }
                    
                    // Изменяем транзакции
                    if let transactions = response.updated?.transactions {
                        for transaction in transactions {
                            try? self.realm.write({
                                self.realm.add(transaction, update: .modified)
                            })
                        }
                    }
                    
                    // Удаляем транзакции
                    if let ids = response.deleted?.transactionsID {
                        try? self.realm.write {
                            self.realm.delete(self.realm.objects(Transaction.self).filter("id in (%@)", ids))
                        }
                    }
                    
                    // Добавляем счета
                    if let accounts = response.created?.accounts {
                        try? self.realm.write {
                            self.realm.add(accounts)
                        }
                    }
                    
                    // Изменяем счета
                    if let accounts = response.updated?.accounts {
                        for account in accounts {
                            try? self.realm.write({
                                self.realm.add(account, update: .modified)
                            })
                        }
                    }
                    
                    // Удаляем счета
                    if let ids = response.deleted?.accoutnsID {
                        try? self.realm.write {
                            self.realm.delete(self.realm.objects(Account.self).filter("id in (%@)", ids))
                        }
                    }
                }
            }
        }
    }
    
    func deleteTransaction(id: Int, _ settings: AppSettings) {
        
        TransactionAPI().DeleteTransaction(id: id) { error in
            
            if let err = error {
                settings.showErrorAlert(error: err)
            } else {
                try? self.realm.write {
                    self.realm.delete(self.realm.objects(Transaction.self).filter("id = %@", id))
                }
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

