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
    
    static func compareTwoArrays(_ serverModels: [CurrencyDB], _ localModels: [CurrencyDB]) -> [String: [String: (server: Any, local: Any)]] {
        let serverModels = serverModels.sorted { $0.code < $1.code }
        let localModels = localModels.sorted { $0.code < $1.code }
        
        var differences: [String: [String: (server: Any, local: Any)]] = [:]
        
        guard serverModels.count == localModels.count else {
            var difference: [String: (server: Any, local: Any)] = ["count": (server: serverModels.count, local: localModels.count)]
            differences[""] = difference
            return differences
        }
        
        for (i, serverModel) in serverModels.enumerated() {
            var difference: [String: (server: Any, local: Any)] = [:]
            if serverModel.code != localModels[i].code {
                difference["code"] = (server: serverModel.code, local: localModels[i].code)
            }
            if serverModel.name != localModels[i].name {
                difference["name"] = (server: serverModel.name, local: localModels[i].name)
            }
            if serverModel.rate != localModels[i].rate {
                difference["rate"] = (server: serverModel.rate, local: localModels[i].rate)
            }
            if serverModel.symbol != localModels[i].symbol {
                difference["symbol"] = (server: serverModel.symbol, local: localModels[i].symbol)
            }
            if !difference.isEmpty {
                differences[serverModel.code] = difference
            }
        }
        return differences
    }
}

// MARK: - Persistence
extension CurrencyDB: Codable, FetchableRecord, PersistableRecord {
    enum Columns {
        static let code = Column(CodingKeys.code)
        static let name = Column(CodingKeys.name)
        static let rate = Column(CodingKeys.rate)
        static let symbol = Column(CodingKeys.symbol)
    }
}
