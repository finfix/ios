//
//  Account.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation
import GRDB

struct AccountDB {
    
    var id: UInt32
    var accounting: Bool
    var iconID: UInt32
    var name: String
    var remainder: Decimal
    var type: AccountType
    var visible: Bool
    var parentAccountId: UInt32?
    var serialNumber: UInt32
    var isParent: Bool
    var currencyCode: String
    var accountGroupId: UInt32
    var budgetAmount: Decimal
    var budgetFixedSum: Decimal
    var budgetDaysOffset: UInt8
    var budgetGradualFilling: Bool
    var datetimeCreate: Date
    
    init(
        id: UInt32,
        accounting: Bool,
        iconID: UInt32,
        name: String,
        remainder: Decimal,
        type: AccountType,
        visible: Bool,
        parentAccountId: UInt32?,
        serialNumber: UInt32,
        isParent: Bool,
        currencyCode: String,
        accountGroupId: UInt32,
        budgetAmount: Decimal,
        budgetFixedSum: Decimal,
        budgetDaysOffset: UInt8,
        budgetGradualFilling: Bool,
        datetimeCreate: Date
    ) {
        self.id = id
        self.accounting = accounting
        self.iconID = iconID
        self.name = name
        self.remainder = remainder
        self.type = type
        self.visible = visible
        self.parentAccountId = parentAccountId
        self.serialNumber = serialNumber
        self.isParent = isParent
        self.currencyCode = currencyCode
        self.accountGroupId = accountGroupId
        self.budgetAmount = budgetAmount
        self.budgetFixedSum = budgetFixedSum
        self.budgetDaysOffset = budgetDaysOffset
        self.budgetGradualFilling = budgetGradualFilling
        self.datetimeCreate = datetimeCreate
    }
    
    // Инициализатор из сетевой модели
    init(_ res: GetAccountsRes) {
        self.id = res.id
        self.accounting = res.accounting
        self.iconID = res.iconID
        self.name = res.name
        self.remainder = res.remainder
        self.type = res.type
        self.visible = res.visible
        self.parentAccountId = res.parentAccountID
        self.serialNumber = res.serialNumber
        self.isParent = res.isParent
        self.budgetAmount = res.budget.amount
        self.budgetFixedSum = res.budget.fixedSum
        self.budgetDaysOffset = res.budget.daysOffset
        self.budgetGradualFilling = res.budget.gradualFilling
        self.accountGroupId = res.accountGroupID
        self.currencyCode = res.currency
        self.datetimeCreate = res.datetimeCreate
    }
    
    // Инициализатор из бизнес модели
    init(_ model: Account) {
        self.id = model.id
        self.accounting = model.accounting
        self.iconID = model.iconID
        self.name = model.name
        self.remainder = model.remainder
        self.type = model.type
        self.visible = model.visible
        self.parentAccountId = model.parentAccountID
        self.serialNumber = model.serialNumber
        self.isParent = model.isParent
        self.budgetAmount = model.budgetAmount
        self.budgetFixedSum = model.budgetFixedSum
        self.budgetDaysOffset = model.budgetDaysOffset
        self.budgetGradualFilling = model.budgetGradualFilling
        self.accountGroupId = model.accountGroup.id
        self.currencyCode = model.currency.code
        self.parentAccountId = model.parentAccountID
        self.datetimeCreate = model.datetimeCreate
    }
    
    
    static func convertFromApiModel(_ accounts: [GetAccountsRes]) -> [AccountDB] {
        var accountsDB: [AccountDB] = []
        for account in accounts {
            accountsDB.append(AccountDB(account))
        }
        return accountsDB
    }
}

// MARK: - Persistence
extension AccountDB: Codable, FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let accounting = Column(CodingKeys.accounting)
        static let iconID = Column(CodingKeys.iconID)
        static let name = Column(CodingKeys.name)
        static let remainder = Column(CodingKeys.remainder)
        static let type = Column(CodingKeys.type)
        static let visible = Column(CodingKeys.visible)
        static let parentAccountId = Column(CodingKeys.parentAccountId)
        static let serialNumber = Column(CodingKeys.serialNumber)
        static let isParent = Column(CodingKeys.isParent)
        static let currencyCode = Column(CodingKeys.currencyCode)
        static let accountGroupId = Column(CodingKeys.accountGroupId)
        static let budgetAmount = Column(CodingKeys.budgetAmount)
        static let budgetFixedSum = Column(CodingKeys.budgetFixedSum)
        static let budgetDaysOffset = Column(CodingKeys.budgetDaysOffset)
        static let budgetGradualFilling = Column(CodingKeys.budgetGradualFilling)
        static let datetimeCreate = Column(CodingKeys.datetimeCreate)
    }
}
