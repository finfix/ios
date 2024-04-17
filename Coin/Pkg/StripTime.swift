//
//  StripDate.swift
//  Coin
//
//  Created by Илья on 03.04.2024.
//

import Foundation

extension Date {
    func stripTime() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        components.timeZone = TimeZone(identifier: "UTC")
        let date = Calendar.current.date(from: components)
        return date!
    }
}
