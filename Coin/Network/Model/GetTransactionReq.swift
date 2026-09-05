//
//  CreateTransactionModel.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation

struct GetTransactionReq: Codable {
    var accountID: UUID?
    var dateFrom: Date
    var dateTo: Date
    var type: String?
    var offset: UInt32?
    var limit: UInt8?
}
