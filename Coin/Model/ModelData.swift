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
    }
    
    func deleteAllData() {
        accounts.removeAll()
        accountGroups.removeAll()
    }
}

