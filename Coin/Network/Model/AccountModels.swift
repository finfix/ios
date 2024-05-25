//
//  AccountModels.swift
//  Coin
//
//  Created by Илья on 31.05.2023.
//

import Foundation

struct GetAccountsReq: Encodable {
    var accountGroupID: UInt32?
    var accountingInHeader: Bool?
    var dateFrom: Date?
    var dateTo: Date?
    var type: String?
}

struct GetAccountsRes: Decodable {
    var id: UInt32
    var accountingInHeader: Bool
    var accountingInCharts: Bool
    var budget: GetAccountBudgetRes
    var iconID: UInt32
    var name: String
    var remainder: Decimal
    var type: AccountType
    var visible: Bool
    var parentAccountID: UInt32?
    var currency: String
    var accountGroupID: UInt32
    var serialNumber: UInt32
    var isParent: Bool
    var datetimeCreate: Date
}

struct GetAccountBudgetRes: Decodable {
    var amount: Decimal
    var fixedSum: Decimal
    var gradualFilling: Bool
    var daysOffset: Int8
}

struct CreateAccountReq: Encodable, FieldExtractable {
    var accountGroupID: UInt32
    var accountingInHeader: Bool
    var accountingInCharts: Bool
    var budget: CreateAccountBudgetReq
    var currency: String
    var iconID: UInt32
    var name: String
    var remainder: Decimal?
    var type: String
    var isParent: Bool
    var parentAccountID: UInt32?
    var datetimeCreate: Date
    
    init(
        accountGroupID: UInt32,
        accountingInHeader: Bool,
        accountingInCharts: Bool,
        budget: CreateAccountBudgetReq,
        currency: String,
        iconID: UInt32,
        name: String,
        remainder: Decimal? = nil,
        type: String,
        isParent: Bool,
        parentAccountID: UInt32? = nil,
        datetimeCreate: Date
    ) {
        self.accountGroupID = accountGroupID
        self.accountingInHeader = accountingInHeader
        self.accountingInCharts = accountingInCharts
        self.budget = budget
        self.currency = currency
        self.iconID = iconID
        self.name = name
        self.remainder = remainder
        self.type = type
        self.isParent = isParent
        self.parentAccountID = parentAccountID
        self.datetimeCreate = datetimeCreate
    }
    
    init(_ map: [String: String]) {
        self.accountGroupID = UInt32(map["accountGroupID"]!)!
        self.accountingInHeader = Bool(map["accountingInHeader"]!)!
        self.accountingInCharts = Bool(map["accountingInCharts"]!)!
        self.budget = CreateAccountBudgetReq(
            amount: Decimal(string: map["budget.amount"]!)!,
            gradualFilling: Bool(map["budget.gradualFilling"]!)!,
            daysOffset: Int8(map["budget.daysOffset"]!)!,
            fixedSum: Decimal(string: map["budget.fixedSum"]!)!
        )
        self.currency = map["currency"]!
        self.iconID = UInt32(map["iconID"]!)!
        self.name = map["name"]!
        self.remainder = Decimal(string: map["remainder"] ?? "")
        self.type = map["type"]!
        self.isParent = Bool(map["isParent"]!)!
        self.parentAccountID = UInt32(map["parentAccountID"] ?? "")
        self.datetimeCreate = DateFormatters.fullTime.date(from: map["datetimeCreate"]!)!
    }
    
    func convertToFields() -> [SyncTaskValue] {
        var fields: [SyncTaskValue] = []
        fields.append(SyncTaskValue(objectType: .accountGroup, name: "accountGroupID", value: String(self.accountGroupID)))
        fields.append(SyncTaskValue(name: "accountingInHeader", value: String(self.accountingInHeader)))
        fields.append(SyncTaskValue(name: "accountingInCharts", value: String(self.accountingInCharts)))
        
        fields.append(SyncTaskValue(name: "budget.amount", value: self.budget.amount.stringValue))
        fields.append(SyncTaskValue(name: "budget.gradualFilling", value: String(self.budget.gradualFilling)))
        fields.append(SyncTaskValue(name: "budget.daysOffset", value: String(self.budget.daysOffset)))
        fields.append(SyncTaskValue(name: "budget.fixedSum", value: self.budget.fixedSum.stringValue))
        
        fields.append(SyncTaskValue(name: "currency", value: self.currency))
        fields.append(SyncTaskValue(objectType: .icon, name: "iconID", value: String(self.iconID)))
        fields.append(SyncTaskValue(name: "name", value: self.name))
        if let remainder = self.remainder {
            fields.append(SyncTaskValue(name: "remainder", value: remainder.stringValue))
        }
        fields.append(SyncTaskValue(name: "type", value: String(self.type)))
        fields.append(SyncTaskValue(name: "isParent", value: String(self.isParent)))
        if let parentAccountID = self.parentAccountID {
            fields.append(SyncTaskValue(objectType: .account, name: "parentAccountID", value: String(parentAccountID)))
        }
        fields.append(SyncTaskValue(name: "datetimeCreate", value: DateFormatters.fullTime.string(from: self.datetimeCreate)))
        return fields
    }
}

struct CreateAccountBudgetReq: Encodable {
    var amount: Decimal
    var gradualFilling: Bool
    var daysOffset: Int8
    var fixedSum: Decimal
}


struct CreateAccountRes: Decodable {
    var id: UInt32
    var serialNumber: UInt32
    var balancingTransactionID: UInt32?
    var balancingAccountID: UInt32?
    var balancingAccountSerialNumber: UInt32?
}

struct UpdateAccountRes: Decodable {
    var balancingTransactionID: UInt32?
    var balancingAccountID: UInt32?
    var balancingAccountSerialNumber: UInt32?
}

struct UpdateAccountReq: Encodable, FieldExtractable {
    var id: UInt32
    var accountingInHeader: Bool?
    var accountingInCharts: Bool?
    var name: String?
    var remainder: Decimal?
    var visible: Bool?
    var currencyCode: String?
    var parentAccountID: UInt32?
    var iconID: UInt32?
    var serialNumber: UInt32?
    var budget: UpdateBudgetReq
    
    init(
        id: UInt32,
        accountingInHeader: Bool? = nil,
        accountingInCharts: Bool? = nil,
        name: String? = nil,
        remainder: Decimal? = nil,
        visible: Bool? = nil,
        currencyCode: String? = nil,
        parentAccountID: UInt32? = nil,
        iconID: UInt32? = nil,
        serialNumber: UInt32? = nil,
        budget: UpdateBudgetReq
    ) {
        self.id = id
        self.accountingInHeader = accountingInHeader
        self.accountingInCharts = accountingInCharts
        self.name = name
        self.remainder = remainder
        self.visible = visible
        self.currencyCode = currencyCode
        self.parentAccountID = parentAccountID
        self.iconID = iconID
        self.serialNumber = serialNumber
        self.budget = budget
    }
    
    init(_ map: [String: String]) {
        self.id = UInt32(map["id"]!)!
        self.accountingInHeader = Bool(map["accountingInHeader"] ?? "")
        self.accountingInCharts = Bool(map["accountingInCharts"] ?? "")
        self.name = map["name"]
        self.remainder = Decimal(string: map["remainder"] ?? "")
        self.visible = Bool(map["visible"] ?? "")
        self.currencyCode = map["currencyCode"]
        self.parentAccountID = UInt32(map["parentAccountID"] ?? "")
        self.iconID = UInt32(map["iconID"] ?? "")
        self.serialNumber = UInt32(map["serialNumber"] ?? "")
        self.budget = UpdateBudgetReq(
            amount: Decimal(string: map["budget.amount"] ?? ""),
            fixedSum: Decimal(string: map["budget.fixedSum"] ?? ""),
            daysOffset: Int8(map["budget.daysOffset"] ?? ""),
            gradualFilling: Bool(map["budget.gradualFilling"] ?? "")
        )
    }
    
    func convertToFields() -> [SyncTaskValue] {
        var fields: [SyncTaskValue] = []
        fields.append(SyncTaskValue(objectType: .account, name: "id", value: String(id)))
        if let accountingInHeader = self.accountingInHeader {
            fields.append(SyncTaskValue(name: "accountingInHeader", value: String(accountingInHeader)))
        }
        if let accountingInCharts = self.accountingInCharts {
            fields.append(SyncTaskValue(name: "accountingInCharts", value: String(accountingInCharts)))
        }
        if let name = self.name {
            fields.append(SyncTaskValue(name: "name", value: name))
        }
        if let remainder = self.remainder {
            fields.append(SyncTaskValue(name: "remainder", value: remainder.stringValue))
        }
        if let visible = self.visible {
            fields.append(SyncTaskValue(name: "visible", value: String(visible)))
        }
        if let currencyCode = self.currencyCode {
            fields.append(SyncTaskValue(name: "currencyCode", value: currencyCode))
        }
        if let parentAccountID = self.parentAccountID {
            fields.append(SyncTaskValue(objectType: .account, name: "parentAccountID", value: String(parentAccountID)))
        }
        if let iconID = self.iconID {
            fields.append(SyncTaskValue(name: "iconID", value: String(iconID)))
        }
        if let serialNumber = self.serialNumber {
            fields.append(SyncTaskValue(name: "serialNumber", value: String(serialNumber)))
        }
        if let amount = self.budget.amount {
            fields.append(SyncTaskValue(name: "budget.amount", value: amount.stringValue))
        }
        if let fixedSum = self.budget.fixedSum {
            fields.append(SyncTaskValue(name: "budget.fixedSum", value: fixedSum.stringValue))
        }
        if let daysOffset = self.budget.daysOffset {
            fields.append(SyncTaskValue(name: "budget.daysOffset", value: String(daysOffset)))
        }
        if let gradualFilling = self.budget.gradualFilling {
            fields.append(SyncTaskValue(name: "budget.gradualFilling", value: String(gradualFilling)))
        }
        return fields
    }
}

struct UpdateBudgetReq: Encodable {
    var amount: Decimal?
    var fixedSum: Decimal?
    var daysOffset: Int8?
    var gradualFilling: Bool?
}

struct DeleteAccountReq: Encodable, FieldExtractable {
    var id: UInt32
    
    init(
        id: UInt32
    ) {
        self.id = id
    }
    
    init(_ map: [String: String]) {
        self.id = UInt32(map["id"]!)!
    }
    
    func convertToFields() -> [SyncTaskValue] {
        var fields: [SyncTaskValue] = []
        fields.append(SyncTaskValue(objectType: .account, name: "id", value: String(self.id)))
        return fields
    }
}
