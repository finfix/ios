//
//  Currencies.swift
//  Coin
//
//  Created by Илья on 21.10.2023.
//

import Foundation
import GRDB

struct Currency: Hashable, Codable {
    
    static func == (lhs: Currency, rhs: Currency) -> Bool {
        return lhs.code == rhs.code
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
    
    var code: String
    var name: String
    var rate: Decimal
    var symbol: String
    
    init(code: String = "", name: String = "", rate: Decimal = 1, symbol: String = "") {
        self.code = code
        self.name = name
        self.rate = rate
        self.symbol = symbol
    }
    
    init(_ res: GetCurrenciesRes) {
        self.code = res.isoCode
        self.name = res.name
        self.symbol = res.symbol
        self.rate = res.rate
    }
}

extension Currency: TableRecord, FetchableRecord, EncodableRecord, PersistableRecord {}

