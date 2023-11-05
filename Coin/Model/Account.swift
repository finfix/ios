//
//  Order.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import Foundation
import SwiftData

@Model class Account: Decodable, Identifiable {
    
    @Attribute(.unique) var id: UInt32
    var accountGroupID: UInt32
    var accounting: Bool
    var budget: Decimal
    var currency: String
    var iconID: UInt32
    var name: String
    var remainder: Decimal
    var type: AccountType
    var visible: Bool
    var parentAccountID: UInt32?
    var gradualBudgetFilling: Bool
    
    @Transient var childrenAccounts: [Account] = []
    @Transient var showingBudget: Decimal = 0
    @Transient var showingRemainder: Decimal = 0
    
    func clearTransientData() {
        self.childrenAccounts = []
        self.showingBudget = 0
        self.showingRemainder = 0
    }
    
    init(
        id: UInt32 = 0,
        accountGroupID: UInt32 = 0,
        accounting: Bool = true,
        budget: Decimal = 0,
        currency: String = "RUB",
        iconID: UInt32 = 1,
        name: String = "",
        remainder: Decimal = 0,
        type: AccountType = .regular,
        visible: Bool = true,
        parentAccountID: UInt32? = nil,
        childrenAccounts: [Account] = [Account](),
        gradualBudgetFilling: Bool = false) {
        self.id = id
        self.accountGroupID = accountGroupID
        self.accounting = accounting
        self.budget = budget
        self.currency = currency
        self.iconID = iconID
        self.name = name
        self.remainder = remainder
        self.type = type
        self.visible = visible
        self.parentAccountID = parentAccountID
        self.childrenAccounts = childrenAccounts
        self.gradualBudgetFilling = gradualBudgetFilling
    }

    private enum CodingKeys: String, CodingKey {
        case id, accountGroupID, accounting, budget, currency, iconID, name, remainder, type, visible, parentAccountID, gradualBudgetFilling
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UInt32.self, forKey: .id)
        accountGroupID = try container.decode(UInt32.self, forKey: .accountGroupID)
        accounting = try container.decode(Bool.self, forKey: .accounting)
        budget = try container.decode(Decimal.self, forKey: .budget)
        currency = try container.decode(String.self, forKey: .currency)
        iconID = try container.decode(UInt32.self, forKey: .iconID)
        name = try container.decode(String.self, forKey: .name)
        remainder = try container.decode(Decimal.self, forKey: .remainder)
        type = try container.decode(AccountType.self, forKey: .type)
        visible = try container.decode(Bool.self, forKey: .visible)
        parentAccountID = try container.decode(UInt32?.self, forKey: .parentAccountID)
        gradualBudgetFilling = try container.decode(Bool.self, forKey: .gradualBudgetFilling)
    }
}

func groupAccounts(_ accounts: [Account]) -> [Account] {
    
    let check = Date()
    
    let rates = Currencies.rates
    
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
                
                account.showingBudget = account.budget
                account.showingRemainder = account.remainder
                
                // Добавляем его в дочерние счета родителя
                accountsContainer[parentAccountIndex].childrenAccounts.append(account)
                
                // Аггрегируем бюджеты и остатки, если необхдоимо
                if account.accounting {
                    let relation = (rates[parentAccount.currency] ?? 1) / (rates[account.currency] ?? 1)
                    accountsContainer[parentAccountIndex].showingBudget += account.budget * relation
                    accountsContainer[parentAccountIndex].showingRemainder += account.remainder * relation
                }
            }
            
        } else {
            // Проверяем, чтобы такого счета уже не было в контейнере
            guard accountsContainer.firstIndex(where: { $0.id == account.id }) == nil else { continue }
            account.showingBudget = account.budget
            account.showingRemainder = account.remainder
            // Добавляем счет в контейнер
            accountsContainer.append(account)
        }
    }
    return accountsContainer
}


extension Account: Hashable {
    
    static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum AccountType: String, Codable, CaseIterable {
    case expense, earnings, debt, regular
}
