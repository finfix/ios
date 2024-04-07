//
//  StripDate.swift
//  Coin
//
//  Created by Илья on 03.04.2024.
//

import Foundation

extension Date {
    func stripTime() -> Date {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        let date = Calendar.current.date(from: components)
        return date!
    }
}
