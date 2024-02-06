//
//  Order.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import Foundation
import SwiftData

@Model class Account {
    
    @Attribute(.unique) var id: UInt32
    var accounting: Bool
    var iconID: UInt32
    var name: String
    var remainder: Decimal
    var type: AccountType
    var visible: Bool
    var parentAccountID: UInt32?
    var serialNumber: UInt32
    var isParent: Bool
    var currency: Currency?
    var accountGroup: AccountGroup?
    var budgetAmount: Decimal
    var budgetFixedSum: Decimal
    var budgetDaysOffset: UInt8
    var budgetGradualFilling: Bool

    @Transient var childrenAccounts: [Account] = []
    @Transient var showingBudget: Decimal = 0
    @Transient var showingRemainder: Decimal = 0
    
    init(
        id: UInt32 = 0,
        accountGroup: AccountGroup = AccountGroup(),
        currency: Currency = Currency(),
        accounting: Bool = true,
        budgetAmount: Decimal = 0,
        budgetFixedSum: Decimal = 0,
        budgetDaysOffset: UInt8 = 0,
        budgetGradualFilling: Bool = false,
        iconID: UInt32 = 1,
        name: String = "",
        remainder: Decimal = 0,
        type: AccountType = .regular,
        visible: Bool = true,
        serialNumber: UInt32 = 0,
        isParent: Bool = false,
        parentAccountID: UInt32? = nil
    ) {
        self.id = id
        self.accounting = accounting
        self.budgetAmount = budgetAmount
        self.budgetFixedSum = budgetFixedSum
        self.budgetDaysOffset = budgetDaysOffset
        self.budgetGradualFilling = budgetGradualFilling
        self.iconID = iconID
        self.name = name
        self.remainder = remainder
        self.type = type
        self.visible = visible
        self.parentAccountID = parentAccountID
        self.serialNumber = serialNumber
        self.isParent = isParent
        self.accountGroup = accountGroup
        self.currency = currency
    }
    
    init(_ res: GetAccountsRes, currenciesMap: [String: Currency], accountGroupsMap: [UInt32: AccountGroup]) {
        self.id = res.id
        self.accounting = res.accounting
        self.iconID = res.iconID
        self.name = res.name
        self.remainder = res.remainder
        self.type = res.type
        self.visible = res.visible
        self.parentAccountID = res.parentAccountID
        self.serialNumber = res.serialNumber
        self.isParent = res.isParent
        self.budgetAmount = res.budget.amount
        self.budgetFixedSum = res.budget.fixedSum
        self.budgetDaysOffset = res.budget.daysOffset
        self.budgetGradualFilling = res.budget.gradualFilling
        self.accountGroup = accountGroupsMap[res.accountGroupID]!
        self.currency = currenciesMap[res.currency]!
    }
    
    static func groupAccounts(_ accounts: [Account]) -> [Account] {
                    
        for account in accounts {
            account.clearTransientData()
        }

        // Делаем контейнер для сбора счетов и счетов с аггрегацией
        var accountsContainer = [Account]()
            
        for account in accounts {
            
            // Если у элемента исходного массива есть родитель
            if let parentAccountID = account.parentAccountID {
                
                // Индекс родителя в контейнере
                var parentAccountIndex: Int = 0
                
                // Ищем индекс родителя в контейнере
                if let index = accountsContainer.firstIndex(where: { $0.id == parentAccountID }) {
                    // Если находим, присваиваем переменной
                    parentAccountIndex = index
                    
                // Если не находим
                } else {
                    
                    // Добавляем родителя из accounts в контейнер
                    if let parentAccount = accounts.first(where: { $0.id == parentAccountID }) {
                        accountsContainer.append(parentAccount)
                        
                        // Получаем его индекс
                        parentAccountIndex = accountsContainer.firstIndex(where: { $0.id == parentAccountID })!
                    } else {
                        continue
                    }
                }
                
                // Получаем родителя
                let parentAccount = accountsContainer[parentAccountIndex]
                
                // Если счет нужно показывать
                if account.visible {
                    
                    account.showingBudget = account.budgetAmount
                    account.showingRemainder = account.remainder
                    
                    // Добавляем его в дочерние счета родителя
                    accountsContainer[parentAccountIndex].childrenAccounts.append(account)
                    
                    // Аггрегируем бюджеты и остатки, если необхдоимо
                    if account.accounting {
                        let relation = (parentAccount.currency?.rate ?? 1) / (account.currency?.rate ?? 1)
                        accountsContainer[parentAccountIndex].showingBudget += account.budgetAmount * relation
                        accountsContainer[parentAccountIndex].showingRemainder += account.remainder * relation
                    }
                }
                
            } else {
                // Проверяем, чтобы такого счета уже не было в контейнере
                account.showingBudget += account.budgetAmount
                account.showingRemainder += account.remainder
                guard accountsContainer.firstIndex(where: { $0.id == account.id }) == nil else { continue }
                // Добавляем счет в контейнер
                accountsContainer.append(account)
            }
        }
        return accountsContainer
    }
    
    func clearTransientData() {
        self.childrenAccounts = []
        self.showingBudget = 0
        self.showingRemainder = 0
    }
}

enum AccountType: String, Codable, CaseIterable {
    case expense, earnings, debt, regular
}




struct AccountPermissions {
    var changeBudget: Bool = true
    var changeRemainder: Bool = true
    var linkToParentAccount: Bool = true
}

private let typeToPermissions: [AccountType: AccountPermissions] = [
    // Разрешения для счетов долгов - нельзя менять только бюджеты
    .debt: AccountPermissions(
        changeBudget: false,
        changeRemainder: true,
        linkToParentAccount: true
    ),
    // Разрешения для счетов доходов - нельзя менять только остатки счетов
    .earnings: AccountPermissions(
        changeBudget: true,
        changeRemainder: false,
        linkToParentAccount: true
    ),
    // Разрешения для обычных счетов - нельзя менять только бюджеты
    .regular: AccountPermissions(
        changeBudget: false,
        changeRemainder: true,
        linkToParentAccount: true
    ),
    // Разрешения для счетов расходов - нельзя менять только остатки счетов
    .expense: AccountPermissions(
        changeBudget: true,
        changeRemainder: false,
        linkToParentAccount: true
    )
]

private let isParentToPermissions: [Bool: AccountPermissions] = [
    // Разрешения для дочерних счетов - все разрешения
    false: AccountPermissions(
        changeBudget: true,
        changeRemainder: true,
        linkToParentAccount: true
    ),
    // Разрешения для родительских счетов - нельзя менять остатки счетов, создавать транзакции и привязывать к родительским счетам
    true: AccountPermissions(
        changeBudget: true,
        changeRemainder: true,
        linkToParentAccount: true
    )
]

func GetPermissions(account: Account) -> AccountPermissions {
    return joinPermissions(permissions: [
        typeToPermissions[account.type]!,
        isParentToPermissions[account.isParent]!
    ])
}

private func joinPermissions(permissions: [AccountPermissions]) -> AccountPermissions {
    var joinedPermissions = AccountPermissions()
    for permission in permissions {
        joinedPermissions.changeBudget = joinedPermissions.changeBudget && permission.changeBudget
        joinedPermissions.changeRemainder = joinedPermissions.changeRemainder && permission.changeRemainder
        joinedPermissions.linkToParentAccount = joinedPermissions.linkToParentAccount && permission.linkToParentAccount
    }
    return joinedPermissions
}
