//
//  CurrencyFormatter.swift
//  Coin
//
//  Created by Илья on 22.10.2023.
//

import Foundation

enum NumberFormatters {
    static let textField: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = " "
        formatter.zeroSymbol = ""
        formatter.maximumFractionDigits = 7
        return formatter
    }()
}
