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
}
