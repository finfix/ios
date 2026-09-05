//
//  AccountBudgetModels.swift
//  Coin
//

import Foundation

struct GetAccountBudgetsReq: Codable {
    var accountGroupIDs: [UUID] = []
    var dateFrom: Date?
    var dateTo: Date?
}
