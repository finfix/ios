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
    var budget: Decimal
    var iconID: UInt32
    var name: String
    var remainder: Decimal
    var type: AccountType
    var visible: Bool
    var parentAccountID: UInt32?
    var gradualBudgetFilling: Bool
    var currency: String
    var accountGroupID: UInt32
    var serialNumber: UInt32
}

struct CreateAccountReq: Encodable {
    var accountGroupID: UInt32
    var accounting: Bool
    var budget: Decimal?
    var currency: String
    var iconID: UInt32
    var name: String
    var remainder: Decimal?
    var type: String
    var gradualBudgetFilling: Bool
}

struct CreateAccountRes: Decodable {
    var id: UInt32
}

struct UpdateAccountReq: Encodable {
    var id: UInt32
    var accounting: Bool?
    var budget: Decimal?
//    var iconID: UInt32?
    var name: String?
    var remainder: Decimal?
    var visible: Bool?
    var gradualBudgetFilling: Bool?
}

struct GetAccountGroupsRes: Decodable {
    var id: UInt32
    var name: String
    var currency: String
    var serialNumber: UInt32
}
