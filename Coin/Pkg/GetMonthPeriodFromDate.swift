//
//  GetMonthPeriodFromDate.swift
//  Coin
//
//  Created by Илья on 03.04.2024.
//

import Foundation

func getMonthPeriodFromDate(_ date: Date) -> (Date, Date) {
    var calendar = Calendar.current
    calendar.timeZone = TimeZone.current
    let dateComponents = calendar.dateComponents([.year, .month], from: date)
    let dateFrom = calendar.date(from: DateComponents(timeZone: TimeZone.current, year: dateComponents.year, month: dateComponents.month, day: 1))!
    let dateTo = calendar.date(from: DateComponents(timeZone: TimeZone.current, year: dateComponents.year, month: dateComponents.month! + 1, day: 1))!
    return (dateFrom, dateTo)
}
