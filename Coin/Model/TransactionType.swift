//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import Foundation
import ProtoDefinitions

enum TransactionType: String, Codable, CaseIterable {
    case consumption, income, transfer, balancing
    
    var name: String {
        switch self {
        case .consumption: return "Расход"
        case .income: return "Доход"
        case .transfer: return "Перевод"
        case .balancing: return "Балансировка"
        }
    }
}
