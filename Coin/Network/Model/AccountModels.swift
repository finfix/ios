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
    var iconID: UUID
    var name: String
    var remainder: Decimal
    var type: AccountType
    var visible: Bool
    var parentAccountID: UUID?
    var currency: String
    var accountGroupID: UUID
    var rank: String
    var isParent: Bool
    var datetimeCreate: Date
    var linkedAccountID: UUID?
}

struct CreateAccountReq: Codable {
    var id: UUID
    var accountGroupID: UUID
    var accountingInHeader: Bool
    var accountingInCharts: Bool
    var currency: String
    var iconID: UUID
    var name: String
    var type: String
    var isParent: Bool
    var parentAccountID: UUID?
    var datetimeCreate: Date
    var rank: String

    init(
        id: UUID,
        accountGroupID: UUID,
        accountingInHeader: Bool,
        accountingInCharts: Bool,
        currency: String,
        iconID: UUID,
        name: String,
        type: String,
        isParent: Bool,
        parentAccountID: UUID? = nil,
        datetimeCreate: Date,
        rank: String
    ) {
        self.id = id
        self.accountGroupID = accountGroupID
        self.accountingInHeader = accountingInHeader
        self.accountingInCharts = accountingInCharts
        self.currency = currency
        self.iconID = iconID
        self.name = name
        self.type = type
        self.isParent = isParent
        self.parentAccountID = parentAccountID
        self.datetimeCreate = datetimeCreate
        self.rank = rank
    }
}

struct CreateAccountRes: Decodable {
}

struct UpdateAccountRes: Decodable {
}

struct UpdateAccountReq: Codable {
    var id: UUID
    var accountingInHeader: Bool?
    var accountingInCharts: Bool?
    var name: String?
    var visible: Bool?
    var currencyCode: String?
    var parentAccountID: UUID?
    var iconID: UUID?
    var rank: String?
    var linkedAccountID: UUID?
    var unlinkAccount: Bool

    var hasChanges: Bool {
        accountingInHeader != nil || accountingInCharts != nil || name != nil ||
        visible != nil || currencyCode != nil || parentAccountID != nil ||
        iconID != nil || rank != nil || linkedAccountID != nil || unlinkAccount
    }

    init(
        id: UUID,
        accountingInHeader: Bool? = nil,
        accountingInCharts: Bool? = nil,
        name: String? = nil,
        visible: Bool? = nil,
        currencyCode: String? = nil,
        parentAccountID: UUID? = nil,
        iconID: UUID? = nil,
        rank: String? = nil,
        linkedAccountID: UUID? = nil,
        unlinkAccount: Bool = false
    ) {
        self.id = id
        self.accountingInHeader = accountingInHeader
        self.accountingInCharts = accountingInCharts
        self.name = name
        self.visible = visible
        self.currencyCode = currencyCode
        self.parentAccountID = parentAccountID
        self.iconID = iconID
        self.rank = rank
        self.linkedAccountID = linkedAccountID
        self.unlinkAccount = unlinkAccount
    }
}

struct DeleteAccountReq: Codable {
    var id: UUID
    
    init(
        id: UUID
    ) {
        self.id = id
    }
}
