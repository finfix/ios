//
//  ChartView.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import SwiftUI
import Charts

enum ChartDisplayType: CaseIterable {
    case linear, ring
    
    var name: String {
        switch self {
        case .linear: "Линейный"
        case .ring: "Кольцевой"
        }
    }
}
