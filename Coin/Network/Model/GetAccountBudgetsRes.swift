//
//  AccountBudgetModels.swift
//  Coin
//

import Foundation

struct GetAccountBudgetsRes: Decodable {
    var id: UUID
    var accountID: UUID
    var amount: Decimal
    var fixedSum: Decimal
    var daysOffset: Int8
    var gradualFilling: Bool
    var effectiveFrom: Date
    var createdByUserID: UUID
    var datetimeCreate: Date
    var accountGroupID: UUID
}
