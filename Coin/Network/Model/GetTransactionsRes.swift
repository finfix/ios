//
//  CreateTransactionModel.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation

struct GetTransactionsRes: Decodable {
    var id: UUID
    var accountingInCharts: Bool
    var amountFrom: Decimal
    var amountTo: Decimal
    var dateTransaction: Date
    var isExecuted: Bool
    var note: String
    var type: TransactionType
    var accountFromID: UUID
    var accountToID: UUID
    var datetimeCreate: Date
    var accountGroupID: UUID
    
    enum CodingKeys: String, CodingKey {
        case id
        case accountingInCharts
        case amountFrom
        case amountTo
        case dateTransaction
        case isExecuted
        case note
        case type
        case accountFromID
        case accountToID
        case datetimeCreate
        case accountGroupID
    }
}
