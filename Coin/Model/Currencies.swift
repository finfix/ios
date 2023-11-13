//
//  Currencies.swift
//  Coin
//
//  Created by Илья on 21.10.2023.
//

import Foundation
import SwiftData

@Model class Currency: Decodable {
    
    @Attribute(.unique) var isoCode: String
    var name: String
    var rate: Decimal
    var symbol: String
    
    init(isoCode: String = "USD", name: String = "", rate: Decimal = 1, symbol: String = "") {
        self.isoCode = isoCode
        self.name = name
        self.rate = rate
        self.symbol = symbol
    }
    
    enum CodingKeys: CodingKey {
        case isoCode, name, rate, symbol
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isoCode = try container.decode(String.self, forKey: .isoCode)
        name = try container.decode(String.self, forKey: .name)
        rate = try container.decode(Decimal.self, forKey: .rate)
        symbol = try container.decode(String.self, forKey: .symbol)
    }
    
    func getByIsoCode(_ isoCode: String, context: ModelContext) -> Currency {
        let descriptor = FetchDescriptor<Currency>(predicate: #Predicate { $0.isoCode == isoCode })
        let currencies = (try? context.fetch(descriptor)) ?? []
        if let currency = currencies.first {
            return currency
        }
        return Currency()
    }
}
