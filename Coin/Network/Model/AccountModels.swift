//
//  AccountModels.swift
//  Coin
//
//  Created by Илья on 31.05.2023.
//

import Foundation

struct GetAccountsReq: Codable {
    var accountGroupID: UUID?
    var accountingInHeader: Bool?
    var dateFrom: Date?
    var dateTo: Date?
    var type: String?
}

struct GetAccountsRes: Decodable {
    var id: UUID
    var accountingInHeader: Bool
    var accountingInCharts: Bool
    var budget: GetAccountBudgetRes
    var iconID: UUID
    var name: String
    var remainder: Decimal
    var type: AccountType
    var visible: Bool
    var parentAccountID: UUID?
    var currency: String
    var accountGroupID: UUID
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

struct CreateAccountReq: Codable {
    var accountGroupID: UUID
    var accountingInHeader: Bool
    var accountingInCharts: Bool
    var budget: CreateAccountBudgetReq
    var currency: String
    var iconID: UUID
    var name: String
    var remainder: Decimal?
    var type: String
    var isParent: Bool
    var parentAccountID: UUID?
    var datetimeCreate: Date
    
    init(
        accountGroupID: UUID,
        accountingInHeader: Bool,
        accountingInCharts: Bool,
        budget: CreateAccountBudgetReq,
        currency: String,
        iconID: UUID,
        name: String,
        remainder: Decimal? = nil,
        type: String,
        isParent: Bool,
        parentAccountID: UUID? = nil,
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
}

struct CreateAccountBudgetReq: Codable {
    var amount: Decimal
    var gradualFilling: Bool
    var daysOffset: Int8
    var fixedSum: Decimal
}


struct CreateAccountRes: Decodable {
    var id: UUID
    var serialNumber: UInt32
    var balancingTransactionID: UUID?
    var balancingAccountID: UUID?
    var balancingAccountSerialNumber: UInt32?
}

struct UpdateAccountRes: Decodable {
    var balancingTransactionID: UUID?
    var balancingAccountID: UUID?
    var balancingAccountSerialNumber: UInt32?
}

struct UpdateAccountReq: Codable {
    var id: UUID
    var accountingInHeader: Bool?
    var accountingInCharts: Bool?
    var name: String?
    var remainder: Decimal?
    var visible: Bool?
    var currencyCode: String?
    var parentAccountID: UUID?
    var iconID: UUID?
    var serialNumber: UInt32?
    var budget: UpdateBudgetReq
    
    init(
        id: UUID,
        accountingInHeader: Bool? = nil,
        accountingInCharts: Bool? = nil,
        name: String? = nil,
        remainder: Decimal? = nil,
        visible: Bool? = nil,
        currencyCode: String? = nil,
        parentAccountID: UUID? = nil,
        iconID: UUID? = nil,
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
}

struct UpdateBudgetReq: Codable {
    var amount: Decimal?
    var fixedSum: Decimal?
    var daysOffset: Int8?
    var gradualFilling: Bool?
}

struct DeleteAccountReq: Codable {
    var id: UUID
    
    init(
        id: UUID
    ) {
        self.id = id
    }
}
