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
    
    init(selectedAccountGroup: AccountGroup) {
        self.selectedAccountGroup = selectedAccountGroup
    }
        
    var selectedAccountGroup: AccountGroup
    var accounts: [Account] = []
    var statistic = QuickStatistic()
    
    func load() {
        do {
            accounts = try service.getAccounts()
            statistic = calculateStatistic(accounts: accounts, targetCurrency: selectedAccountGroup.currency)
        } catch {
            showErrorAlert("\(error)")
        }
    }
    
    func calculateStatistic(accounts a: [Account], targetCurrency: Currency) -> QuickStatistic {
        var tmp = QuickStatistic(currency: targetCurrency)
        
        let accounts = Account.groupAccounts(a)
        
        for account in accounts {
            
            if account.parentAccountID != nil {
                continue
            }
                        
            let relation = targetCurrency.rate / (account.currency.rate)
            
            switch account.type {
            case .expense:
                tmp.totalExpense += account.remainder * relation
                tmp.totalBudget += account.budgetAmount * relation
                if account.budgetAmount != 0 && account.budgetAmount > account.remainder {
                    tmp.periodRemainder += (account.budgetAmount - account.remainder) * relation
                }
            case .earnings:
                continue
            default:
                tmp.totalRemainder += account.remainder * relation
            }
        }
        return tmp
    }
}
