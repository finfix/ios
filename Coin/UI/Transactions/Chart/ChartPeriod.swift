//
//  ChartViewModel.swift
//  Coin
//
//  Created by Илья on 15.04.2024.
//

import Foundation
import SwiftUI
import Factory

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

    // Ограничение глубины истории по умолчанию (nil = без ограничений). Для подневного
    // графика отсчитываем год назад не всегда от "сейчас", а от даты "До" фильтра,
    // если она задана — иначе при выбранном диапазоне в прошлом график всё равно тянул
    // данные относительно текущей даты. Когда пользователь доскроллит до края этого года,
    // кнопки на графике (см. Graph.swift) расширяют сам фильтр ещё на полгода.
    func defaultDateFrom(relativeTo dateTo: Date?) -> Date? {
        switch self {
        case .day: (dateTo ?? Date.now).adding(.year, value: -1)
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
