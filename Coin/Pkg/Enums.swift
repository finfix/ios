//
//  Enums.swift
//  Coin
//
//  Created by Илья on 14.01.2023.
//

import SwiftUI

enum TransactionType {
    case consumption, income, transfer
    
    var description : String {
        switch self {
        case .consumption: return "consumption"
        case .income: return "income"
        case .transfer: return "transfer"
        }
    }
}

enum AccountPick {
    case from, to
}
