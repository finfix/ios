//
//  Order.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import Foundation
import OSLog
private let logger = Logger(subsystem: "Coin", category: "AccountModel")

struct Account: Identifiable {
    
    indirect enum Parent: ExpressibleByNilLiteral {
        init(nilLiteral: ()) {
            self = .none
        }
        
        case none
        case account(Account)
        
        var account: Account? {
            if case .account(let account) = self {
                return account
            }
            return nil
        }
    }
    
    var id: UInt32
    var accountingInHeader: Bool
    var accountingInCharts: Bool
    var icon: Icon
    var name: String
    var remainder: Decimal
    var showingRemainder: Decimal
    var type: AccountType
    var visible: Bool
    var serialNumber: UInt32
    var isParent: Bool
    var budgetAmount: Decimal
    var showingBudgetAmount: Decimal
    var budgetFixedSum: Decimal
    var budgetDaysOffset: UInt8
    var budgetGradualFilling: Bool
    var datetimeCreate: Date
    
    var parentAccountID: UInt32?
    var parentAccount: Parent
    
    var accountGroup: AccountGroup
    var currency: Currency
    
    var childrenAccounts: [Account]
    
    init(
        id: UInt32 = 0,
        accountingInHeader: Bool = true,
        accountingInCharts: Bool = true,
        icon: Icon = Icon(),
        name: String = "",
        remainder: Decimal = 0,
        showingRemainder: Decimal = 0,
        type: AccountType = .regular,
        visible: Bool = true,
        serialNumber: UInt32 = 0,
        isParent: Bool = false,
        budgetAmount: Decimal = 0,
        showingBudgetAmount: Decimal = 0,
        budgetFixedSum: Decimal = 0,
        budgetDaysOffset: UInt8 = 0,
        budgetGradualFilling: Bool = false,
        datetimeCreate: Date = Date.now,
        parentAccountID: UInt32? = nil,
        parentAccount: Account.Parent = nil,
        accountGroup: AccountGroup = AccountGroup(),
        currency: Currency = Currency(),
        childrenAccounts: [Account] = []
    ) {
        self.id = id
        self.accountingInHeader = accountingInHeader
        self.accountingInCharts = accountingInCharts
        self.icon = icon
        self.name = name
        self.remainder = remainder
        self.showingRemainder = showingRemainder
        self.type = type
        self.visible = visible
        self.parentAccountID = parentAccountID
        self.parentAccount = parentAccount
        self.serialNumber = serialNumber
        self.isParent = isParent
        self.budgetAmount = budgetAmount
        self.showingBudgetAmount = showingBudgetAmount
        self.budgetFixedSum = budgetFixedSum
        self.budgetDaysOffset = budgetDaysOffset
        self.budgetGradualFilling = budgetGradualFilling
        self.datetimeCreate = datetimeCreate
        self.accountGroup = accountGroup
        self.currency = currency
        self.childrenAccounts = childrenAccounts
    }
    
    // Инициализатор из модели базы данных
    init(
         _ dbModel: AccountDB,
         currenciesMap: [String: Currency]?,
         accountGroupsMap: [UInt32: AccountGroup]?,
         iconsMap: [UInt32: Icon]?
    ) {
        self.id = dbModel.id
        self.accountingInHeader = dbModel.accountingInHeader
        self.accountingInCharts = dbModel.accountingInCharts
        self.name = dbModel.name
        self.remainder = dbModel.remainder
        self.showingRemainder = 0
        self.type = dbModel.type
        self.visible = dbModel.visible
        self.serialNumber = dbModel.serialNumber
        self.isParent = dbModel.isParent
        self.budgetAmount = dbModel.budgetAmount
        self.showingBudgetAmount = 0
        self.budgetFixedSum = dbModel.budgetFixedSum
        self.budgetDaysOffset = dbModel.budgetDaysOffset
        self.budgetGradualFilling = dbModel.budgetGradualFilling
        self.datetimeCreate = dbModel.datetimeCreate
        
        self.parentAccountID = dbModel.parentAccountId
        self.parentAccount = nil
        
        self.icon = iconsMap?[dbModel.iconID] ?? Icon()
        self.accountGroup = accountGroupsMap?[dbModel.accountGroupId] ?? AccountGroup()
        self.currency = currenciesMap?[dbModel.currencyCode] ?? Currency()
        
        self.childrenAccounts = []
    }
    
    static func convertFromDBModel(
        _ accountsDB: [AccountDB],
        currenciesMap: [String: Currency]?,
        accountGroupsMap: [UInt32: AccountGroup]?,
        iconsMap: [UInt32: Icon]?
    ) -> [Account] {
        var accounts: [Account] = []
        for accountDB in accountsDB {
            accounts.append(Account(accountDB, currenciesMap: currenciesMap, accountGroupsMap: accountGroupsMap, iconsMap: iconsMap))
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
    case expense, earnings, debt, regular, balancing
}

extension Account {
    static func groupAccounts(_ accounts: [Account]) -> [Account] {
        
        // Делаем контейнер для сбора счетов и счетов с аггрегацией
        var accountsContainer = [Account]()
        
        // Сортируем счета, чтобы сначала были родительские
        let accounts = accounts.sorted { a, _ in
            a.isParent
        }
        
        // Проходимся по каждому счету
        for account in accounts {
            var account = account
            
            // Присваиваем показываевому бюджету его собственный
            account.showingBudgetAmount = account.budgetAmount
            account.showingRemainder = account.remainder
            
            // Если текущий счет является родительским
            if account.isParent {
                // Добавляем его в контейнер
                accountsContainer.append(account)
            } else { // Если счет не родительский
                
                // Смотрим, есть ли у счета родитель
                if let parentAccountID = account.parentAccountID {
                    
                    // Если есть, ищем индекс родителя в уже обработанных счетах
                    if let parentAccountIndex = accountsContainer.firstIndex(where: { $0.id == parentAccountID }) {
                        
                        // Если находим, то добавляем родительскому бюджету и балансу дочерние значения
                        if accountsContainer[parentAccountIndex].accountingInHeader && !account.accountingInHeader {} else {
                            let relation = (accountsContainer[parentAccountIndex].currency.rate) / (account.currency.rate)
                            accountsContainer[parentAccountIndex].showingRemainder += account.remainder * relation
                            accountsContainer[parentAccountIndex].showingBudgetAmount += account.budgetAmount * relation
                        }
                        
                        // Добавляем родителя в счет
                        account.parentAccount = .account(accountsContainer[parentAccountIndex])
                        
                        // Добавляем счет в дочерние счета родителя
                        accountsContainer[parentAccountIndex].childrenAccounts.append(account)
                        
                        continue
                    } else { // Если не находим
                        
                        // Значит у нас где-то ошибка, раз мы такое допустили и просто логгируем это
                        logger.error("Родительский счет (id: \(parentAccountID)) для (name: \(account.name), id: \(account.id)) отсутствует")
                    }
                }
                
                // Добавляем счет в список обработанных
                
                accountsContainer.append(account)
            }
        }
        for (i, account) in accountsContainer.enumerated() {
            accountsContainer[i].childrenAccounts = account.childrenAccounts.sorted { $0.serialNumber < $1.serialNumber }
        }
        return accountsContainer.sorted { $0.serialNumber < $1.serialNumber }
    }
}
