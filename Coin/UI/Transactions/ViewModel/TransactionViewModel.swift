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
    
    @Environment(\.realm) var realm
    
    //MARK: - Vars
    @Published var transactions = [Transaction]()
    @Published var accounts = [Account]()
    
    var accountsMap: [Int: Account] {
        let accountsMap = Dictionary(uniqueKeysWithValues: accounts.map{ ($0.id, $0) })
        return accountsMap
    }
    
    var transactionByDate: [Date : [Transaction]] {
        Dictionary(grouping: transactionsFiltered, by: { $0.dateTransaction })
    }
    
    var intercurrency: Bool {
        return accountFrom?.currencySignatura != accountTo?.currencySignatura
    }
    
    @Published var transactionType: TransactionTypes?
    @Published var accountFrom: Account?
    @Published var accountTo: Account?
    
    @Published var amountFrom: String = ""
    @Published var amountTo: String = ""
    @Published var selectedType: Int = 0
    @Published var note = ""
    @Published var date = Date()
    
    @Published var searchText = ""
    
    @Published var appSettings = AppSettings()
    
    var transactionsFiltered: [Transaction]  {
        
        var subfiltered = transactions
        
        if searchText != "" {
            subfiltered = subfiltered.filter { ($0.note ?? "").contains(searchText) }
        }
        
        return subfiltered
    }
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
    
    // Получаем счета
    func getAccount() {
        AccountAPI().GetAccounts { model, error in
            if let err = error {
                self.appSettings.showErrorAlert(error: err)
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
                try? self.realm.write {
                    self.realm.delete(self.realm.objects(Transaction.self).filter("id = %@", id))
                }
            }
        }
    }
    
    func createTransaction(_ settings: AppSettings, isOpeningFrame: Binding<Bool>) {
        let format = DateFormatter()
        format.dateFormat = "YYYY-MM-dd"
                
        TransactionAPI().CreateTransaction(req: CreateTransactionRequest(accountFromID: accountFrom!.id, accountToID: accountTo!.id, amountFrom: Double(amountFrom.replacingOccurrences(of: ",", with: ".")) ?? 0, amountTo: (intercurrency ? Double(amountTo.replacingOccurrences(of: ",", with: ".")) : Double(amountFrom.replacingOccurrences(of: ",", with: "."))) ?? 0, dateTransaction: format.string(from: date), note: note, type: transactionType!.description, isExecuted: true)) { error in
            if let err = error {
                settings.showErrorAlert(error: err)
            }
        }
    }
}

