//
//  Currencies.swift
//  Coin
//
//  Created by Илья on 21.10.2023.
//

import Foundation

struct Currency {
    var code: String
    var name: String
    var rate: Decimal
    var symbol: String
    
    init(
        code: String = "",
        name: String = "",
        rate: Decimal = 1,
        symbol: String = ""
    ) {
        self.code = code
        self.name = name
        self.rate = rate
        self.symbol = symbol
    }
    
    // Инициализатор из модели базы данных
    init(_ dbModel: CurrencyDB) {
        self.code = dbModel.code
        self.name = dbModel.name
        self.rate = dbModel.rate
        self.symbol = dbModel.symbol
    }
        
    static func convertFromDBModel(_ currenciesDB: [CurrencyDB]) -> [Currency] {
        var currencies: [Currency] = []
        for currencyDB in currenciesDB {
            currencies.append(Currency(currencyDB))
        }
        return currencies
    }
    
    static func convertToMap(_ currencies: [Currency]) -> [String: Currency] {
        return Dictionary(uniqueKeysWithValues: currencies.map{ ($0.code, $0) })
    }
}

extension Currency: Hashable {
    static func == (lhs: Currency, rhs: Currency) -> Bool {
        return lhs.code == rhs.code
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}
