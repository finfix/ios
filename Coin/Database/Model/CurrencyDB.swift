//
//  Currency.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation
import GRDB

struct CurrencyDB {
    
    var code: String
    var name: String
    var rate: Decimal
    var symbol: String
    
    // Инициализатор из сетевой модели
    init(_ res: GetCurrenciesRes) {
        self.code = res.isoCode
        self.name = res.name
        self.symbol = res.symbol
        self.rate = res.rate
    }
    
    static func convertFromApiModel(_ currencies: [GetCurrenciesRes]) -> [CurrencyDB] {
        var currenciesDB: [CurrencyDB] = []
        for currency in currencies {
            currenciesDB.append(CurrencyDB(currency))
        }
        return currenciesDB
    }
}

// MARK: - Persistence
extension CurrencyDB: Codable, FetchableRecord, PersistableRecord {
    fileprivate enum Columns {
        static let code = Column(CodingKeys.code)
        static let name = Column(CodingKeys.name)
        static let rate = Column(CodingKeys.rate)
        static let symbol = Column(CodingKeys.symbol)
    }
}
