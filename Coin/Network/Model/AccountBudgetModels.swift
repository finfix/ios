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

struct GetAccountBudgetsReq: Codable {
    var accountGroupIDs: [UUID] = []
    var dateFrom: Date?
    var dateTo: Date?
}

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
