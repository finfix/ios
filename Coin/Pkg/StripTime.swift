//
//  StripDate.swift
//  Coin
//
//  Created by Илья on 03.04.2024.
//

import Foundation

extension Date {
    func stripTime(using calendar: Calendar = .current) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: self)
        components.timeZone = TimeZone(identifier: "UTC")
        return calendar.date(from: components)!
    }
    
    func startOfMonth(
        inUTC: Bool = false,
        using calendar: Calendar = .current
    ) -> Date {
        var calendar = calendar
        if inUTC {
            calendar.timeZone = TimeZone(abbreviation: "UTC")!
        }
        return calendar.date(from: calendar.dateComponents([.year, .month], from: self))!
    }
    
    func adding(_ component: Calendar.Component, value: Int, using calendar: Calendar = .current) -> Date {
        return calendar.date(byAdding: component, value: value, to: self)!
    }
    
    // Начало периода в UTC, согласуется с форматами SQLite-запросов
    func startOfPeriod(_ period: ChartPeriod) -> Date {
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        switch period {
        case .day:
            return utcCalendar.date(from: utcCalendar.dateComponents([.year, .month, .day], from: self))!
        case .week:
            // Вычисляем понедельник текущей недели (0=Вс, 1=Пн, ..., 6=Сб)
            let weekday = utcCalendar.component(.weekday, from: self)
            let daysBack = (weekday - 2 + 7) % 7
            let monday = utcCalendar.date(byAdding: .day, value: -daysBack, to: self)!
            return utcCalendar.date(from: utcCalendar.dateComponents([.year, .month, .day], from: monday))!
        case .month:
            return startOfMonth(inUTC: true)
        case .quarter:
            var comps = utcCalendar.dateComponents([.year, .month], from: self)
            let month = comps.month ?? 1
            comps.month = ((month - 1) / 3) * 3 + 1
            comps.day = 1
            return utcCalendar.date(from: comps)!
        case .year:
            var comps = utcCalendar.dateComponents([.year], from: self)
            comps.month = 1
            comps.day = 1
            return utcCalendar.date(from: comps)!
        }
    }
}
