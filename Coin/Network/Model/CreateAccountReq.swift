//
//  AccountModels.swift
//  Coin
//
//  Created by Илья on 31.05.2023.
//

import Foundation

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
