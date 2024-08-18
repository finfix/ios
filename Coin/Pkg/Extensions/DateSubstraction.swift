//
//  DateSubstraction.swift
//  Coin
//
//  Created by Илья on 10.07.2024.
//

import Foundation

extension Date {
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}
