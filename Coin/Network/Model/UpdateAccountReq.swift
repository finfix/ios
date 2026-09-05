//
//  AccountModels.swift
//  Coin
//
//  Created by Илья on 31.05.2023.
//

import Foundation

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
