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
    @Published var accounts = [Account]()
    
    var accountsMap: [UInt32: Account] {
        let accountsMap = Dictionary(uniqueKeysWithValues: accounts.map{ ($0.id, $0) })
        return accountsMap
    }
    
    var transactionByDate: [Date : [Transaction]] {
        Dictionary(grouping: transactionsFiltered, by: { $0.dateTransaction })
    }
    
    var intercurrency: Bool {
        return accountFrom?.currency != accountTo?.currency
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
            subfiltered = subfiltered.filter { ($0.note ?? "").contains(searchText) || $0.accountFromID == UInt32(searchText) || $0.accountToID == UInt32(searchText) }
        }
        
        return subfiltered
    }
    
    //MARK: - Methods
    // Получаем транзакции
    func getTransaction(_ settings: AppSettings) {
        TransactionAPI().GetTransactions(req: GetTransactionRequest(list: 0)) { response, error in
            if let err = error {
                settings.showErrorAlert(error: err)
            } else if let response = response {
                self.transactions = response
            }
        }
    }
    
    // Получаем счета
    func getAccount() {
        AccountAPI().GetAccounts(req: GetAccountsRequest(period: "month"), grouped: false) { model, error in
            if let err = error {
                self.appSettings.showErrorAlert(error: err)
            } else if let response = model {
                self.accounts = response
            }
        }
    }
    
    func deleteTransaction(at offsets: IndexSet, _ settings: AppSettings) {
        
        var id: UInt32 = 0
        
        for i in offsets.makeIterator() {
            id = transactionsFiltered[i].id
        }
        
        TransactionAPI().DeleteTransaction(req: DeleteTransactionRequest(id: id)) { error in
            
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
                
        TransactionAPI().CreateTransaction(req: CreateTransactionRequest(
            accountFromID: accountFrom!.id,
            accountToID: accountTo!.id,
            amountFrom: Double(amountFrom.replacingOccurrences(of: ",", with: ".")) ?? 0,
            amountTo: (intercurrency ? Double(amountTo.replacingOccurrences(of: ",", with: ".")) : Double(amountFrom.replacingOccurrences(of: ",", with: "."))) ?? 0, dateTransaction: format.string(from: date), note: note, type: transactionType!.description, isExecuted: true)) { error in
            if let err = error {
                settings.showErrorAlert(error: err)
            }
        }
    }
}

