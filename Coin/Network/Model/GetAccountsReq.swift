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
