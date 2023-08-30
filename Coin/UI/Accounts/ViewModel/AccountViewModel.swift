//
//  ViewModel.swift
//  Coin
//
//  Created by Илья on 14.10.2022.
//

import SwiftUI

class AccountViewModel: ObservableObject {
    @Published var accounts = [Account]()
    @Published var accountsGrouped = [Account]()
    @Published var quickStatistic = QuickStatisticRes(TotalRemainder: 0, TotalExpense: 0, LeftToSpend: 0, TotalBudget: 0)
    
    // var accountsGrouped: [Account] {
    //     var accountsMap = [UInt32: Account]()
    //     for account in accounts {
    //         accountsMap[account.id] = account
    //     }
    //
    //     for (id, account) in accountsMap {
    //
    //         // Если счет не имеет родителя
    //         if let parentAccountID = account.parentAccountID {
    //
    //             guard var parent = accountsMap[parentAccountID] else {
    //                 continue
    //             }
    //
    //             // Добавляем дочерний счет к родителю
    //             let childAccount = ChildAccount(
    //                 accounting: account.accounting,
    //                 budget: account.budget,
    //                 currency: account.currency,
    //                 iconID: account.iconID,
    //                 id: account.id,
    //                 name: account.name,
    //                 remainder: account.remainder,
    //                 visible: account.visible
    //             )
    //
    //             parent.childrenAccounts?.append(childAccount)
    //
    //             // Получаем отношение валюты пользователя к валюте дочернего счета
    //             guard let userCurrencyRate = rates[user.defaultCurrency],
    //                   let accountCurrencyRate = rates[account.currency] else {
    //                 continue
    //             }
    //
    //             let relation = userCurrencyRate / accountCurrencyRate
    //
    //             // Считаем остаток счета и бюджет в валюте пользователя и добавляем к остатку родителя
    //             parent.remainder += relation * account.remainder
    //             parent.budget += relation * account.budget
    //
    //             // Обновляем родительский счет в словаре
    //             accountsMap[parentAccountID] = parent
    //
    //             // Удаляем дочерний счет из словаря
    //             accountsMap.removeValue(forKey: id)
    //         }
    //     }

    //     // Заменяем счета в исходном массиве счетов, чтобы порядок счетов не менялся
    //     var accountsWithoutChildren = [Account]()
    //     for account in accounts {
    //         if let newAccount = accountsMap[account.id] {
    //             accountsWithoutChildren.append(newAccount)
    //         }
    //     }
    // }
    
    @Published var visible = true
    @Published var accounting = true
    @Published var accountType = 1
    @Published var withoutZeroRemainder = true
    @Published var selectedAccountGroupID: Int = 0
    
    // Возможные типы счетов
    var types = ["earnings", "expense", "regular", "credit", "investment", "debt"]
    
    func getAccount(_ settings: AppSettings) {
        AccountAPI().GetAccounts(req: GetAccountsRequest(period: "month"), grouped: false) { model, error in
            if let err = error {
                settings.showErrorAlert(error: err)
            } else if let response = model {
                self.accounts = response
            }
        }
    }
    
    func getAccountGrouped(_ settings: AppSettings) {
        AccountAPI().GetAccounts(req: GetAccountsRequest(period: "month"), grouped: true) { model, error in
            if let err = error {
                settings.showErrorAlert(error: err)
            } else if let response = model {
                self.accountsGrouped = response
            }
        }
    }
    
    func getQuickStatistic(_ settings: AppSettings) {
        AccountAPI().QuickStatistic { model, error in
            if let err = error {
                settings.showErrorAlert(error: err)
            } else if let response = model {
                self.quickStatistic = response
            }
        }
    }
}


