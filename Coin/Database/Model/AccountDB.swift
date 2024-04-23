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
    var accountingInHeader: Bool
    var accountingInCharts: Bool
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
        accountingInHeader: Bool,
        accountingInCharts: Bool,
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
        self.accountingInHeader = accountingInHeader
        self.accountingInCharts = accountingInCharts
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
        self.accountingInHeader = res.accountingInHeader
        self.accountingInCharts = res.accountingInCharts
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
        self.accountingInHeader = model.accountingInHeader
        self.accountingInCharts = model.accountingInCharts
        self.iconID = model.icon.id
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
    
    static func compareTwoArrays(_ serverModels: [AccountDB], _ localModels: [AccountDB]) -> [UInt32: [String: (server: Any, local: Any)]] {
        let serverModels = serverModels.sorted { $0.id < $1.id }
        let localModels = localModels.sorted { $0.id < $1.id }
        
        var differences: [UInt32: [String: (server: Any, local: Any)]] = [:]
        
        guard serverModels.count == localModels.count else {
            var difference: [String: (server: Any, local: Any)] = ["count": (server: serverModels.count, local: localModels.count)]
            differences[0] = difference
            return differences
        }
        
        for (i, serverModel) in serverModels.enumerated() {
            var difference: [String: (server: Any, local: Any)] = [:]
            if serverModel.id != localModels[i].id {
                difference["id"] = (server: serverModel.id, local: localModels[i].id)
            }
            if serverModel.accountingInHeader != localModels[i].accountingInHeader {
                difference["accountingInHeader"] = (server: serverModel.accountingInHeader, local: localModels[i].accountingInHeader)
            }
            if serverModel.accountingInCharts != localModels[i].accountingInCharts {
                difference["accountingInCharts"] = (server: serverModel.accountingInCharts, local: localModels[i].accountingInCharts)
            }
            if serverModel.iconID != localModels[i].iconID {
                difference["iconID"] = (server: serverModel.iconID, local: localModels[i].iconID)
            }
            if serverModel.name != localModels[i].name {
                difference["name"] = (server: serverModel.name, local: localModels[i].name)
            }
            if serverModel.remainder != localModels[i].remainder {
                difference["remainder"] = (server: serverModel.remainder, local: localModels[i].remainder)
            }
            if serverModel.type != localModels[i].type {
                difference["type"] = (server: serverModel.type, local: localModels[i].type)
            }
            if serverModel.visible != localModels[i].visible {
                difference["visible"] = (server: serverModel.visible, local: localModels[i].visible)
            }
            if serverModel.parentAccountId != localModels[i].parentAccountId {
                difference["parentAccountId"] = (server: serverModel.parentAccountId ?? 0, local: localModels[i].parentAccountId ?? 0)
            }
            if serverModel.serialNumber != localModels[i].serialNumber {
                difference["serialNumber"] = (server: serverModel.serialNumber, local: localModels[i].serialNumber)
            }
            if serverModel.isParent != localModels[i].isParent {
                difference["isParent"] = (server: serverModel.isParent, local: localModels[i].isParent)
            }
            if serverModel.currencyCode != localModels[i].currencyCode {
                difference["currencyCode"] = (server: serverModel.currencyCode, local: localModels[i].currencyCode)
            }
            if serverModel.accountGroupId != localModels[i].accountGroupId {
                difference["accountGroupId"] = (server: serverModel.accountGroupId, local: localModels[i].accountGroupId)
            }
            if serverModel.budgetAmount != localModels[i].budgetAmount {
                difference["budgetAmount"] = (server: serverModel.budgetAmount, local: localModels[i].budgetAmount)
            }
            if serverModel.budgetFixedSum != localModels[i].budgetFixedSum {
                difference["budgetFixedSum"] = (server: serverModel.budgetFixedSum, local: localModels[i].budgetFixedSum)
            }
            if serverModel.budgetDaysOffset != localModels[i].budgetDaysOffset {
                difference["budgetDaysOffset"] = (server: serverModel.budgetDaysOffset, local: localModels[i].budgetDaysOffset)
            }
            if serverModel.budgetGradualFilling != localModels[i].budgetGradualFilling {
                difference["budgetGradualFilling"] = (server: serverModel.budgetGradualFilling, local: localModels[i].budgetGradualFilling)
            }
            if serverModel.datetimeCreate != localModels[i].datetimeCreate {
                difference["datetimeCreate"] = (server: serverModel.datetimeCreate, local: localModels[i].datetimeCreate)
            }
            
            if !difference.isEmpty {
                differences[serverModel.id] = difference
            }
        }
        return differences
    }
}

// MARK: - Persistence
extension AccountDB: Codable, FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let accountingInHeader = Column(CodingKeys.accountingInHeader)
        static let accountingInCharts = Column(CodingKeys.accountingInCharts)
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
