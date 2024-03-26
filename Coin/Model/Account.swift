//
//  Order.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import Foundation

struct Account: Identifiable {
    var id: UInt32
    var accounting: Bool
    var iconID: UInt32
    var name: String
    var remainder: Decimal
    var type: AccountType
    var visible: Bool
    var serialNumber: UInt32
    var isParent: Bool
    var budgetAmount: Decimal
    var budgetFixedSum: Decimal
    var budgetDaysOffset: UInt8
    var budgetGradualFilling: Bool
    
    var parentAccountID: UInt32?
    
    var accountGroup: AccountGroup
    var currency: Currency
    
    var childrenAccounts: [Account]
    
    init(
            id: UInt32 = 0,
            accounting: Bool = true,
            iconID: UInt32 = 1,
            name: String = "",
            remainder: Decimal = 0,
            type: AccountType = .regular,
            visible: Bool = true,
            serialNumber: UInt32 = 0,
            isParent: Bool = false,
            budgetAmount: Decimal = 0,
            budgetFixedSum: Decimal = 0,
            budgetDaysOffset: UInt8 = 0,
            budgetGradualFilling: Bool = false,
            parentAccountID: UInt32? = nil,
            accountGroup: AccountGroup = AccountGroup(),
            currency: Currency = Currency(),
            childrenAccounts: [Account] = []
        ) {
            self.id = id
            self.accounting = accounting
            self.iconID = iconID
            self.name = name
            self.remainder = remainder
            self.type = type
            self.visible = visible
            self.parentAccountID = parentAccountID
            self.serialNumber = serialNumber
            self.isParent = isParent
            self.budgetAmount = budgetAmount
            self.budgetFixedSum = budgetFixedSum
            self.budgetDaysOffset = budgetDaysOffset
            self.budgetGradualFilling = budgetGradualFilling
            self.accountGroup = accountGroup
            self.currency = currency
            self.childrenAccounts = childrenAccounts
        }
    
    // Инициализатор из модели базы данных
    init(_ dbModel: AccountDB, currenciesMap: [String: Currency]?, accountGroupsMap: [UInt32: AccountGroup]?) {
        self.id = dbModel.id
        self.accounting = dbModel.accounting
        self.iconID = dbModel.iconID
        self.name = dbModel.name
        self.remainder = dbModel.remainder
        self.type = dbModel.type
        self.visible = dbModel.visible
        self.serialNumber = dbModel.serialNumber
        self.isParent = dbModel.isParent
        self.budgetAmount = dbModel.budgetAmount
        self.budgetFixedSum = dbModel.budgetFixedSum
        self.budgetDaysOffset = dbModel.budgetDaysOffset
        self.budgetGradualFilling = dbModel.budgetGradualFilling
        
        self.parentAccountID = dbModel.parentAccountId
        
        self.accountGroup = accountGroupsMap?[dbModel.accountGroupId]! ?? AccountGroup()
        self.currency = currenciesMap?[dbModel.currencyCode]! ?? Currency()
        
        self.childrenAccounts = []
    }
    
    static func convertFromDBModel(_ accountsDB: [AccountDB], currenciesMap: [String: Currency]?, accountGroupsMap: [UInt32: AccountGroup]?) -> [Account] {
        var accounts: [Account] = []
        for accountDB in accountsDB {
            accounts.append(Account(accountDB, currenciesMap: currenciesMap, accountGroupsMap: accountGroupsMap))
        }
        return accounts
    }
    
    static func convertToMap(_ accounts: [Account]) -> [UInt32: Account] {
        return Dictionary(uniqueKeysWithValues: accounts.map{ ($0.id, $0) })
    }
}

extension Account: Hashable {
    
    static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum AccountType: String, Codable, CaseIterable {
    case expense, earnings, debt, regular
}

extension Account {
    static func groupAccounts(_ accounts: [Account]) -> [Account] {

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
                                        
                    // Добавляем его в дочерние счета родителя
                    accountsContainer[parentAccountIndex].childrenAccounts.append(account)
                    
                    // Аггрегируем бюджеты и остатки, если необхдоимо
                    if account.accounting {
                        let relation = (parentAccount.currency.rate) / (account.currency.rate)
                        accountsContainer[parentAccountIndex].budgetAmount += account.budgetAmount * relation
                        accountsContainer[parentAccountIndex].remainder += account.remainder * relation
                    }
                }
                
            } else {
                // Проверяем, чтобы такого счета уже не было в контейнере
                guard accountsContainer.firstIndex(where: { $0.id == account.id }) == nil else { continue }
                // Добавляем счет в контейнер
                accountsContainer.append(account)
            }
        }
        return accountsContainer
    }
}
