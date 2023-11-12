//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import Foundation
import SwiftData

@Model 
class Transaction: Decodable {
    @Attribute(.unique)
    var id: UInt32
    var accounting: Bool
    var amountFrom: Decimal
    var amountTo: Decimal
    var dateTransaction: Date
    var isExecuted: Bool
    var note: String
    var type: TransactionType
    
    var accountFrom: Account?
    var accountTo: Account?
    
    var accountFromID: UInt32
    var accountToID: UInt32
    
    init(accountFromID: UInt32 = 0, accountToID: UInt32 = 0, accounting: Bool = true, amountFrom: Decimal = 0, amountTo: Decimal = 0, dateTransaction: Date = Date(), id: UInt32 = 0, isExecuted: Bool = true, note: String = "", type: TransactionType = .consumption) {
        self.accountFromID = accountFromID
        self.accountToID = accountToID
        self.accounting = accounting
        self.amountFrom = amountFrom
        self.amountTo = amountTo
        self.dateTransaction = dateTransaction
        self.id = id
        self.isExecuted = isExecuted
        self.note = note
        self.type = type
    }
    
    enum CodingKeys: CodingKey {
        case accountFromID, accountToID, accounting, amountFrom, amountTo, dateTransaction, id, isExecuted, note, type
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accountFromID = try container.decode(UInt32.self, forKey: .accountFromID)
        accountToID = try container.decode(UInt32.self, forKey: .accountToID)
        accounting = try container.decode(Bool.self, forKey: .accounting)
        amountFrom = try container.decode(Decimal.self, forKey: .amountFrom)
        amountTo = try container.decode(Decimal.self, forKey: .amountTo)
        dateTransaction = try container.decode(Date.self, forKey: .dateTransaction)
        id = try container.decode(UInt32.self, forKey: .id)
        isExecuted = try container.decode(Bool.self, forKey: .isExecuted)
        note = try container.decode(String.self, forKey: .note)
        type = try container.decode(TransactionType.self, forKey: .type)
    }
    
    func filter(_ filters: TransactionFilters) -> Bool {
        if let note = filters.note {
            if !self.note.localizedStandardContains(note) {
                return false
            }
        }
        return true
    }
}

struct TransactionFilters {
    var note: String?
    var dateFrom: Date?
    var dateTo: Date?
}

enum TransactionType: String, Codable {
    case consumption, income, transfer, balancing
}
