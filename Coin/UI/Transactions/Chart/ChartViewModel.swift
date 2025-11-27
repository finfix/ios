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
    case earningsAndExpenses, earnings, expenses
    
    var name: String {
        switch self {
        case .earningsAndExpenses: return "Доходы и расходы"
        case .earnings: return "Доходы"
        case .expenses: return "Расходы"
        }
    }
}

@Observable
class ChartViewModel {
    
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var chartType: ChartType
    var data: [Series] = []
    
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
            case .average2:
                result[series.id] = data.filter{ $0.id == series.id }.first!.data.values.reduce(0) { $0 + $1 / Decimal(data.first!.data.filter{ !$1.isZero }.count) }
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
    
    enum AggregationMethod: CaseIterable {
        case total, average, average2, percent, min, max, budget
        
        var name: String {
            switch self {
            case .total: "Всего"
            case .average: "Среднее"
            case .average2: "Среднее*"
            case .percent: "Процент"
            case .min: "Миниммум"
            case .max: "Максимум"
            case .budget: "Бюджет"
            }
        }
    }
    
    var aggregationMethod: AggregationMethod = .percent
    
    init(chartType: ChartType) {
        self.chartType = chartType
    }
    
    @MainActor
    func load(
        groupBy: ChartViewGroupBy,
        filters: TransactionFilters,
        targetCurrency: Currency
    ) async throws {
        
        var accountIDs: [UUID] = []
        for account in filters.accounts {
            accountIDs.append(account.id)
            for childAccount in account.childrenAccounts {
                accountIDs.append(childAccount.id)
            }
        }
        
        data = try await service.getStatisticByMonth(
            chartType: chartType,
            groupBy: groupBy,
            targetCurrency: targetCurrency,
            accountGroupIDs: filters.accountGroups.map(\.id),
            accountIDs: accountIDs,
            dateFrom: filters.dateFrom,
            dateTo: filters.dateTo,
            tagIDs: filters.tags.map(\.id)
        )
    }
}

enum SeriesType: Hashable {
    case income, expense
    
    var name: String {
        switch self {
        case .income: "Доход"
        case .expense: "Расход"
        }
    }
}

struct Series: Identifiable, Hashable {
    let id = UUID()
    var account: Account?
    var tag: Tag?
    var type: SeriesType?
    var objectID: UUID?
    var serialNumber: UInt32 = 0
    var color: Color = .white
    var data: [Date: Decimal]
}
