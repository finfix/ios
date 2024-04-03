//
//  GetMonthPeriodFromDate.swift
//  Coin
//
//  Created by Илья on 03.04.2024.
//

import Foundation

func getMonthPeriodFromDate(_ date: Date) -> (Date, Date) {
    let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    let dateFrom = Calendar.current.date(from: DateComponents(year: dateComponents.year, month: dateComponents.month, day: 1))!
    let dateTo = Calendar.current.date(from: DateComponents(year: dateComponents.year, month: dateComponents.month! + 1, day: 1))!
    return (dateFrom, dateTo)
}
