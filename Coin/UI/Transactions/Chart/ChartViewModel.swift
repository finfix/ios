//
//  ChartViewModel.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import Foundation
import SwiftUI
import Factory
import os

private let logger = Logger(subsystem: "Coin", category: "ChartViewModel")

enum ChartPeriod: CaseIterable {
    case day, week, month, quarter, year

    var name: String {
        switch self {
        case .day: "День"
        case .week: "Нед."
        case .month: "Мес."
        case .quarter: "Кв."
        case .year: "Год"
        }
    }

    var calendarComponent: Calendar.Component {
        switch self {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        case .quarter: .quarter
        case .year: .year
        }
    }

    var defaultVisibleRange: Int {
        switch self {
        case .day: 30
        case .week: 8
        case .month: 6
        case .quarter: 4
        case .year: 3
        }
    }

    var secondsPerUnit: Int {
        switch self {
        case .day: 60 * 60 * 24
        case .week: 60 * 60 * 24 * 7
        case .month: 60 * 60 * 24 * 30
        case .quarter: 60 * 60 * 24 * 91
        case .year: 60 * 60 * 24 * 365
        }
    }

    // Ограничение глубины истории по умолчанию (nil = без ограничений)
    var defaultDateFrom: Date? {
        switch self {
        case .day: Date.now.adding(.month, value: -6)
        case .week: nil
        case .month: nil
        case .quarter: nil
        case .year: nil
        }
    }

    // Подпись выбранной даты под графиком
    func selectedDateLabel(for date: Date) -> String {
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        switch self {
        case .day:
            return date.formatted(.dateTime.year(.defaultDigits).month(.wide).day())
        case .week:
            let weekNum = utcCalendar.component(.weekOfYear, from: date)
            let endOfWeek = utcCalendar.date(byAdding: .day, value: 6, to: date)!
            let startStr = date.formatted(.dateTime.month(.abbreviated).day())
            let endStr = endOfWeek.formatted(.dateTime.year(.defaultDigits).month(.abbreviated).day())
            return "Нед. \(weekNum) (\(startStr) – \(endStr))"
        case .month:
            return date.formatted(.dateTime.year(.defaultDigits).month(.wide))
        case .quarter:
            let month = utcCalendar.component(.month, from: date)
            let year = utcCalendar.component(.year, from: date)
            let quarterNum = (month - 1) / 3 + 1
            let roman = ["I", "II", "III", "IV"][quarterNum - 1]
            let endMonth = quarterNum * 3
            var endComps = DateComponents()
            endComps.year = year
            endComps.month = endMonth
            endComps.day = 1
            let endMonthDate = utcCalendar.date(from: endComps)!
            let startStr = date.formatted(.dateTime.month(.abbreviated))
            let endStr = endMonthDate.formatted(.dateTime.month(.abbreviated))
            return "\(roman) кв. \(year) (\(startStr) – \(endStr))"
        case .year:
            return date.formatted(.dateTime.year(.defaultDigits))
        }
    }

    // SQL-выражение для начала периода
    func sqlStartOf(_ dateExpr: String) -> String {
        switch self {
        case .day:
            return dateExpr
        case .week:
            return "date(\(dateExpr), '-' || CAST((CAST(strftime('%w', \(dateExpr)) AS INTEGER) + 6) % 7 AS TEXT) || ' days')"
        case .month:
            return "strftime('%Y-%m-01', \(dateExpr))"
        case .quarter:
            return "strftime('%Y-', \(dateExpr)) || printf('%02d', ((CAST(strftime('%m', \(dateExpr)) AS INTEGER) - 1) / 3) * 3 + 1) || '-01'"
        case .year:
            return "strftime('%Y-01-01', \(dateExpr))"
        }
    }
}

enum ChartType: CaseIterable {
    case earningsAndExpenses, earnings, expenses, balance
    
    var name: String {
        switch self {
        case .earningsAndExpenses: return "Доходы и расходы"
        case .earnings: return "Доходы"
        case .expenses: return "Расходы"
        case .balance: return "В наличии"
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
    var aggregateIntoParents: Bool = true
    var period: ChartPeriod = .month
    
    init(chartType: ChartType, aggregateIntoParents: Bool = true) {
        self.chartType = chartType
        self.aggregateIntoParents = aggregateIntoParents
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

        // Для периодов с ограничением истории: используем defaultDateFrom, если фильтр не задаёт явную дату
        let effectiveDateFrom = filters.dateFrom ?? period.defaultDateFrom

        logger.debug("""
            load() called: chartType=\(String(describing: self.chartType), privacy: .public) \
            groupBy=\(String(describing: groupBy), privacy: .public) \
            period=\(String(describing: self.period), privacy: .public) \
            accountGroupIDs=\(filters.accountGroups.map(\.id).map(\.uuidString), privacy: .public) \
            accountIDs=\(accountIDs.map(\.uuidString), privacy: .public) \
            dateFrom=\(String(describing: effectiveDateFrom), privacy: .public) \
            dateTo=\(String(describing: filters.dateTo), privacy: .public) \
            tagIDs=\(filters.tags.map(\.id).map(\.uuidString), privacy: .public)
            """)

        let result = try await service.getStatisticByMonth(
            chartType: chartType,
            groupBy: groupBy,
            period: period,
            targetCurrency: targetCurrency,
            accountGroupIDs: filters.accountGroups.map(\.id),
            accountIDs: accountIDs,
            dateFrom: effectiveDateFrom,
            dateTo: filters.dateTo,
            tagIDs: filters.tags.map(\.id),
            aggregateIntoParents: aggregateIntoParents && groupBy == .byAccount
        )

        logger.debug("""
            load() returned \(result.count, privacy: .public) series: \
            \(result.map { $0.account?.name ?? $0.tag?.name ?? $0.type?.name ?? "?" }, privacy: .public)
            """)

        data = result
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
