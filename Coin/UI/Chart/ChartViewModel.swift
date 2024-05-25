//
//  ChartViewModel.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import Foundation
import SwiftUI

enum ChartType: String, CaseIterable {
    case earningsAndExpenses = "Доходы и расходы"
    case earnings = "Доходы"
    case expenses = "Расходы"
}

@Observable
class ChartViewModel {
    
    let service = Service.shared
    
    var chartType: ChartType
    var data: [Series] = []
    var filters: TransactionFilters
    
    var lastSelectedDate: Date = Date.now.startOfMonth(inUTC: true)
    
    var aggregationInformation: [UUID: Decimal] {
        var result: [UUID: Decimal] = [:]
        let totalBySelectedDate = totalBySelectedDate
        for series in data {
            switch aggregationMethod {
            case .total:
                result[series.id] = data.filter{ $0.id == series.id }.first!.data.values.reduce(0) { $0 + $1 }
            case .average:
                result[series.id] = data.filter{ $0.id == series.id }.first!.data.values.reduce(0) { $0 + $1 / Decimal(data.first!.data.count) }
            case .min:
                result[series.id] = data.filter{ $0.id == series.id }.first!.data.values.min()
            case .max:
                result[series.id] = data.filter{ $0.id == series.id }.first!.data.values.max()
            case .budget:
                result[series.id] = data.filter{ $0.id == series.id }.first!.account?.budgetAmount ?? 0
            case .percent:
                result[series.id] = totalBySelectedDate == 0 ? 0 : (series.data[lastSelectedDate] ?? 0) / totalBySelectedDate
            }
        }
        return result
    }
    
    var totalBySelectedDate: Decimal {
        data.map { $0.data.filter( { $0.key == lastSelectedDate } ).values.reduce(0) { $0 + $1 } }.reduce(0) { $0 + $1 }
    }
        
    enum AggregationMethod: String, CaseIterable {
        case total = "Всего"
        case average = "Среднее"
        case percent = "Процент"
        case min = "Миниммум"
        case max = "Максимум"
        case budget = "Бюджет"
    }
    
    var aggregationMethod: AggregationMethod = .percent
    
    init(
        chartType: ChartType,
        filters: TransactionFilters
    ) {
        self.chartType = chartType
        self.filters = filters
    }
        
    func load(accountGroupID: UInt32) async throws {
        
        var accountIDs: [UInt32] = []
        if let account = filters.account {
            accountIDs = [account.id]
            for childAccount in account.childrenAccounts {
                accountIDs.append(childAccount.id)
            }
        }

        data = try await service.getStatisticByMonth(chartType: chartType, accountGroupID: accountGroupID, accountIDs: accountIDs)
    }
}

struct Series: Identifiable, Hashable {
    let id = UUID()
    var account: Account?
    var type: String
    var serialNumber: UInt32 = 0
    var color: Color = .white
    var data: [Date: Decimal]
}
