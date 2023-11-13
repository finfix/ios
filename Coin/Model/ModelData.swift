//
//  ModelData.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import Foundation

@Observable class ModelData {
    
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
                    
                    if account.visible {
                        accountsTmp[parentAccountIndex!].childrenAccounts.append(account)
                        if account.accounting {
                            let relation = (currencies[parentAccount.currency]?.rate ?? 1) / (currencies[account.currency]?.rate ?? 1)
                            accountsTmp[parentAccountIndex!].budget += account.budget * relation
                            accountsTmp[parentAccountIndex!].remainder += account.remainder * relation
                        }
                    }
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
            if account.type == .earnings || (account.budget == 0 && account.remainder == 0) || !account.childrenAccounts.isEmpty || !account.accounting {
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
        
        Task {
            do {
                self.accounts = try await AccountAPI().GetAccounts(req: GetAccountsReq(dateFrom: dateFrom, dateTo: dateTo))
            } catch {
                debugLog(error)
            }
        }
    }
    
    func getTransactions(offset: UInt32 = 0) {
        
        let limit: UInt8 = 100
        
        Task {
            do {
                let transactions = try await TransactionAPI().GetTransactions(req: GetTransactionReq(offset: offset, limit: limit))
                if offset == 0 {
                    self.transactions = transactions
                } else {
                    self.transactions.append(contentsOf: transactions)
                }
            } catch {
                debugLog(error)
            }
        }
    }
    
    func getAccountGroups() {
        Task {
            do {
                self.accountGroups = try await AccountAPI().GetAccountGroups()
            } catch {
                debugLog(error)
            }
        }
    }
    
    func sync() {
        getAccounts()
        getAccountGroups()
        getTransactions()
    }
    
    func deleteAllData() {
        accounts.removeAll()
        transactions.removeAll()
        accountGroups.removeAll()
    }
}

