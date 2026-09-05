//
//  ChartViewModel.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import Foundation
import SwiftUI
import Factory

enum ChartType: CaseIterable {
    case earningsAndExpenses, earnings, expenses, balance, balanceTotal, delta

    var name: String {
        switch self {
        case .earningsAndExpenses: return "Доходы и расходы"
        case .earnings: return "Доходы"
        case .expenses: return "Расходы"
        case .balance: return "В наличии (детально)"
        case .balanceTotal: return "В наличии (общее)"
        case .delta: return "Дельта"
        }
    }
}
