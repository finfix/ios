//
//  ModelData.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import Foundation

@Observable
class ModelData {
    
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
    var quickStatistic: [UInt32: QuickStatistic] {
        
        let accountGroupsToCurrenciesMap = Dictionary(uniqueKeysWithValues: accountGroups.map{ ($0.id, $0.currency) })
        
        var tmp = [UInt32: QuickStatistic]()
        
        for accountGroup in accountGroups {
            tmp[accountGroup.id] = QuickStatistic(currency: accountGroup.currency)
        }
        
        for account in accounts {
            if account.type == .earnings || (account.budget == 0 && account.remainder == 0) || !account.childrenAccounts.isEmpty {
                continue
            }
            
            let accountGroupCurrency = accountGroupsToCurrenciesMap[account.accountGroupID] ?? account.currency
            
            let relation = (currencies[accountGroupCurrency]?.rate ?? 1) / (currencies[account.currency]?.rate ?? 1)
            
            switch account.type {
            case .expense:
                tmp[account.accountGroupID]?.totalExpense += account.remainder * relation
                tmp[account.accountGroupID]?.totalBudget += account.budget * relation
            case .earnings:
                continue
            default:
                tmp[account.accountGroupID]?.totalRemainder += account.remainder * relation
            }
        }
        return tmp
    }
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
        
        let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let dateFrom = Calendar.current.date(from: DateComponents(year: today.year, month: today.month, day: 1))
        let dateTo = Calendar.current.date(from: DateComponents(year: today.year, month: today.month! + 1, day: 1))
        
        AccountAPI().GetAccounts(req: GetAccountsRequest(dateFrom: dateFrom, dateTo: dateTo)) { model, error in
            if let err = error {
                showErrorAlert(error: err)
            } else if let response = model {
                self.accounts = response
            }
        }
    }
    
    func getTransactions(offset: UInt32 = 0) {
        
        let limit: UInt8 = 100
        
        TransactionAPI().GetTransactions(req: GetTransactionRequest(offset: offset, limit: limit)) { model, error in
            if let err = error {
                showErrorAlert(error: err)
            } else if let response = model {
                if offset == 0 {
                    self.transactions = response
                } else {
                    self.transactions.append(contentsOf: response)
                }
            }
        }
    }
    
    func getAccountGroups() {
        AccountAPI().GetAccountGroups() { model, error in
            if let err = error {
                showErrorAlert(error: err)
            } else if let response = model {
                self.accountGroups = response
            }
        }
    }
    
    func getCurrencies() {
        
        UserAPI().GetCurrencies() { model, error in
            if let err = error {
                showErrorAlert(error: err)
            } else if let response = model {
                self.currencies = Dictionary(uniqueKeysWithValues: response.map{ ($0.isoCode, $0) })
            }
        }
    }
    
    func sync() {
        getAccounts()
        getAccountGroups()
        getTransactions()
        getCurrencies()
    }
    
    func deleteAllData() {
        accounts.removeAll()
        transactions.removeAll()
        accountGroups.removeAll()
    }
}

