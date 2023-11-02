//
//  ModelData.swift
//  Coin
//
//  Created by Илья on 18.10.2023.
//

import Foundation

func groupAccounts(accounts: [Account], currencies: [Currency]) -> [Account] {
    
    var ratesMap: [String: Decimal] {
        Dictionary(uniqueKeysWithValues: currencies.map { ($0.isoCode, $0.rate ) })
    }
    
    for (i, account) in accounts.enumerated() {
        if let parentAccountID = account.parentAccountID {
            let parentAccountIndex = accounts.firstIndex { $0.id == parentAccountID }
            let parentAccount = accounts[parentAccountIndex!]
            
            if account.visible {
                accounts[parentAccountIndex!].childrenAccounts.append(account)
                if account.accounting {
                    let relation = (ratesMap[parentAccount.currency] ?? 1) / (ratesMap[account.currency] ?? 1)
                    accounts[parentAccountIndex!].budget += account.budget * relation
                    accounts[parentAccountIndex!].remainder += account.remainder * relation
                }
            }
            accounts[i].isChild = true
        }
    }
    return accounts
}

@Observable class ModelData {
    
    var accounts = [Account]()
    var accountGroups = [AccountGroup]()
    
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
}

