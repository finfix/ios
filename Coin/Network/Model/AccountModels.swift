//
//  AccountModels.swift
//  Coin
//
//  Created by Илья on 31.05.2023.
//

import Foundation

struct GetAccountsReq: Encodable {
    var accountGroupID: UInt32?
    var accounting: Bool?
    var dateFrom: Date?
    var dateTo: Date?
    var type: String?
}

struct GetAccountsRes: Decodable {
    var id: UInt32
    var accounting: Bool
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
}

struct GetAccountBudgetRes: Decodable {
    var amount: Decimal
    var fixedSum: Decimal
    var gradualFilling: Bool
    var daysOffset: UInt8
}

struct CreateAccountReq: Encodable {
    var accountGroupID: UInt32
    var accounting: Bool
    var budget: CreateAccountBudgetReq
    var currency: String
    var iconID: UInt32
    var name: String
    var remainder: Decimal?
    var type: String
    var isParent: Bool
    var parentAccountID: UInt32?
}

struct CreateAccountBudgetReq: Encodable {
    var amount: Decimal
    var gradualFilling: Bool
}


struct CreateAccountRes: Decodable {
    var id: UInt32
    var serialNumber: UInt32
    var balancingTransactionID: UInt32?
}

struct UpdateAccountRes: Decodable {
    var balancingTransactionID: UInt32?
    var balancingAccountID: UInt32?
    var balancingAccountSerialNumber: UInt32?
}

struct UpdateAccountReq: Encodable {
    var id: UInt32
    var accounting: Bool?
    var name: String?
    var remainder: Decimal?
    var visible: Bool?
    var currencyCode: String?
    var parentAccountID: UInt32?
    var budget: UpdateBudgetReq
}

struct UpdateBudgetReq: Encodable {
    var amount: Decimal?
    var fixedSum: Decimal?
    var daysOffset: UInt8?
    var gradualFilling: Bool?
}

struct GetAccountGroupsRes: Decodable {
    var id: UInt32
    var name: String
    var currency: String
    var serialNumber: UInt32
}
