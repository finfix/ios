//
//  AccountModels.swift
//  Coin
//
//  Created by Илья on 31.05.2023.
//

import Foundation

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
