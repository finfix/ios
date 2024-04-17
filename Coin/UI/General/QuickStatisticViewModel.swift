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
    
    func load() async throws {
        accounts = try await service.getAccounts(accountingInHeader: true)
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
                    if account.showingRemainder < 0 {
                        account.showingRemainder *= -1
                    } else {
                        account.showingRemainder = 0
                    }
                }
                tmp.totalExpense += account.showingRemainder * relation
                tmp.totalBudget += account.showingBudgetAmount * relation
                if account.showingBudgetAmount != 0 && account.showingBudgetAmount > account.showingRemainder {
                    tmp.periodRemainder += (account.showingBudgetAmount - account.showingRemainder) * relation
                }
            case .earnings:
                continue
            case .debt, .regular:
                tmp.totalRemainder += account.showingRemainder * relation
            }
        }
        return tmp
    }
}
