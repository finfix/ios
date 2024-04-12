//
//  QuickStatisticViewModel.swift
//  Coin
//
//  Created by Илья on 01.04.2024.
//

import Foundation

@Observable
class QuickStatisticViewModel {
    private let service = Service.shared
        
    var accounts: [Account] = []
    
    func load() {
        do {
            accounts = try service.getAccounts(accounting: true)
        } catch {
            showErrorAlert("\(error)")
        }
    }
    
    func calculateStatistic(accounts a: [Account], targetCurrency: Currency) -> QuickStatistic {
        var tmp = QuickStatistic(currency: targetCurrency)
        
        let accounts = Account.groupAccounts(a)
        
        for account in accounts {
            var account = account
            
            if account.parentAccountID != nil {
                continue
            }
                        
            let relation = targetCurrency.rate / (account.currency.rate)
            
            switch account.type {
            case .expense, .balancing:
                if account.type == .balancing {
                    if account.remainder < 0 {
                        account.remainder *= -1
                    } else {
                        account.remainder = 0
                    }
                }
                tmp.totalExpense += account.remainder * relation
                tmp.totalBudget += account.showingBudgetAmount * relation
                if account.showingBudgetAmount != 0 && account.showingBudgetAmount > account.remainder {
                    tmp.periodRemainder += (account.showingBudgetAmount - account.remainder) * relation
                }
            case .earnings:
                continue
            case .debt, .regular:
                tmp.totalRemainder += account.remainder * relation
            }
        }
        return tmp
    }
}
