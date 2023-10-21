//
//  ModelData.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import Foundation

@Observable
class ModelData {
    private var appSettings = AppSettings()
    
    var accounts = [Account]()
    var accountsGrouped = [Account]()
    var quickStatistic = QuickStatisticRes()
    var transactions = [Transaction]()
    var accountGroups = [AccountGroup]()
    
    var accountsMap: [UInt32: Account] {
        Dictionary(uniqueKeysWithValues: accounts.map{ ($0.id, $0) })
    }
    
    var filteredAccounts: [Account] {
        if accountGroups.count > 0 {
            return accounts.filter { account in
                account.accountGroupID == accountGroups[selectedAccountsGroupIndex].id
            }
        }
        return []
    }
    
    var filteredGroupedAccounts: [Account] {
        if accountGroups.count > 0 {
            return accountsGrouped.filter { account in
                account.accountGroupID == accountGroups[selectedAccountsGroupIndex].id
            }
        }
        return []
    }
    
    var selectedAccountsGroupIndex: Int = 0
    
    func getAccounts() {
        AccountAPI().GetAccounts(req: GetAccountsRequest(period: "month"), grouped: false) { model, error in
            if let err = error {
                self.appSettings.showErrorAlert(error: err)
            } else if let response = model {
                self.accounts = response
            }
        }
    }
    
    func getAccountsGrouped() {
        AccountAPI().GetAccounts(req: GetAccountsRequest(period: "month"), grouped: true) { model, error in
            if let err = error {
                self.appSettings.showErrorAlert(error: err)
            } else if let response = model {
                self.accountsGrouped = response
            }
        }
    }
    
    func getQuickStatistic() {
        AccountAPI().QuickStatistic() { model, error in
            if let err = error {
                self.appSettings.showErrorAlert(error: err)
            } else if let response = model {
                self.quickStatistic = response
            }
        }
    }
    
    func getTransactions() {
        TransactionAPI().GetTransactions(req: GetTransactionRequest()) { model, error in
            if let err = error {
                self.appSettings.showErrorAlert(error: err)
            } else if let response = model {
                self.transactions = response
            }
        }
    }
    
    func getAccountGroups() {
        AccountAPI().GetAccountGroups() { model, error in
            if let err = error {
                self.appSettings.showErrorAlert(error: err)
            } else if let response = model {
                self.accountGroups = response
            }
        }
    }
    
    func sync() {
        getAccounts()
        getAccountGroups()
        getTransactions()
        getQuickStatistic()
        getAccountsGrouped()
    }
}

