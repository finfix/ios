//
//  Currencies.swift
//  Coin
//
//  Created by Илья on 21.10.2023.
//

import Foundation

@Model class Currency {
    var isoCode: String
    var name: String
    var rate: Double
    var symbol: String
    
    init(isoCode: String = "USD", name: String = "", rate: Double = 1, symbol: String = "") {
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
        rate = try container.decode(Double.self, forKey: .rate)
        symbol = try container.decode(String.self, forKey: .symbol)
    }
}
