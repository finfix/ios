//
//  ChartView.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import SwiftUI
import Charts

enum ChartViewRoute: Hashable {
    case transactionView(filters: TransactionFilters, chartType: ChartType)
    case chartDrillDown(filters: TransactionFilters, chartType: ChartType)
}
