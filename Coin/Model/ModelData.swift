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
    
    var accounts = [Account]() {
        didSet {
            if childrenAccountsUpdated {
                childrenAccountsUpdated = false
                return
            }
            var accountsTmp = accounts
            for (i, account) in accountsTmp.enumerated() {
                if let parentAccountID = account.parentAccountID {
                    let parentAccountIndex = accountsTmp.firstIndex { $0.id == parentAccountID }
                    let parentAccount = accountsTmp[parentAccountIndex!]
                    
                    accountsTmp[parentAccountIndex!].childrenAccounts.append(account)
                    let relation = (currencies[parentAccount.currency] ?? Currency()).rate / (currencies[account.currency] ?? Currency()).rate
                    accountsTmp[parentAccountIndex!].budget += account.budget * relation
                    accountsTmp[parentAccountIndex!].remainder += account.remainder * relation
                    accountsTmp[i].isChild = true
                }
            }
            childrenAccountsUpdated = true
            accounts = accountsTmp
        }
    }
    var childrenAccountsUpdated = false
    var quickStatistic = QuickStatisticRes()
    var transactions = [Transaction]()
    var accountGroups = [AccountGroup]()
    var currencies = [String: Currency]()
    
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
    
    var selectedAccountsGroupIndex: Int = 0
    var selectedAccountsGroupID: UInt32 {
        if accountGroups.count != 0 {
            return accountGroups[selectedAccountsGroupIndex].id
        }
        return 0
    }
    
    func getAccounts() {
        AccountAPI().GetAccounts(req: GetAccountsRequest(period: "month")) { model, error in
            if let err = error {
                self.appSettings.showErrorAlert(error: err)
            } else if let response = model {
                self.accounts = response
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
        TransactionAPI().GetTransactions(req: GetTransactionRequest(list: 0)) { model, error in
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
    
    func getCurrencies() {
        UserAPI().GetCurrencies() { model, error in
            if let err = error {
                self.appSettings.showErrorAlert(error: err)
            } else if let response = model {
                self.currencies = Dictionary(uniqueKeysWithValues: response.map{ ($0.isoCode, $0) })
//                self.accountGroups = response
            }
        }
    }
    
    func sync() {
        getAccounts()
        getAccountGroups()
        getTransactions()
        getQuickStatistic()
        getCurrencies()
    }
}

