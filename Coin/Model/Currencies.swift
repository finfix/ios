//
//  Currencies.swift
//  Coin
//
//  Created by Илья on 21.10.2023.
//

import Foundation
import SwiftData

@Model class Currency {
    
    @Attribute(.unique) var isoCode: String
    var name: String
    var rate: Decimal
    var symbol: String
    
    init(isoCode: String = "", name: String = "", rate: Decimal = 1, symbol: String = "") {
        self.isoCode = isoCode
        self.name = name
        self.rate = rate
        self.symbol = symbol
    }
    
    init(_ res: GetCurrenciesRes) {
        self.isoCode = res.isoCode
        self.name = res.name
        self.symbol = res.symbol
        self.rate = res.rate
    }
}
