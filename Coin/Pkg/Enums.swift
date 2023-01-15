//
//  Enums.swift
//  Coin
//
//  Created by Илья on 14.01.2023.
//

import SwiftUI

enum TransactionTypes {
    case consumption, income, transfer
    
    var description : String {
        switch self {
        case .consumption: return "consumption"
        case .income: return "income"
        case .transfer: return "transfer"
        }
    }
}
