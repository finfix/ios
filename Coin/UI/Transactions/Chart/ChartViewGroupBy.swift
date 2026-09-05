//
//  ChartView.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import SwiftUI
import Charts

enum ChartViewGroupBy: CaseIterable {
    case byTag, byAccount
    
    var name: String {
        switch self {
        case .byAccount: "Счет"
        case .byTag: "Подкатегория"
        }
    }
}
