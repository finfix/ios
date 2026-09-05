//
//  AccountBudgetModels.swift
//  Coin
//

import Foundation

struct CreateAccountBudgetReq: Codable {
    var id: UUID
    var accountID: UUID
    var amount: Decimal
    var fixedSum: Decimal
    var daysOffset: Int8
    var gradualFilling: Bool
    var effectiveFrom: Date
}
