//
//  Currencies.swift
//  Coin
//
//  Created by Илья on 21.10.2023.
//

import Foundation

struct Currency: Identifiable, Hashable {
    
    static func == (lhs: Currency, rhs: Currency) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var id: String
    var name: String
    var rate: Decimal
    var symbol: String
    
    init(id: String = "", name: String = "", rate: Decimal = 1, symbol: String = "") {
        self.id = id
        self.name = name
        self.rate = rate
        self.symbol = symbol
    }
    
    init(_ res: GetCurrenciesRes) {
        self.id = res.id
        self.name = res.name
        self.symbol = res.symbol
        self.rate = res.rate
    }
}
