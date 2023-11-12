//
//  User.swift
//  Coin
//
//  Created by Илья on 30.10.2023.
//

import Foundation
import SwiftData

@Model class User: Decodable {
    
    @Attribute(.unique) var id: UInt32
    var name: String
    var email: String
    var timeCreate: Date
    var defaultCurrencyName: String
    
    var currency: Currency?
    
    init(id: UInt32 = 0, name: String = "", email: String = "", timeCreate: Date = Date(), defaultCurrency: String = "") {
        self.id = id
        self.name = name
        self.email = email
        self.timeCreate = timeCreate
        self.defaultCurrencyName = defaultCurrency
    }
    
    enum CodingKeys: CodingKey {
        case id, name, email, timeCreate, defaultCurrency
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UInt32.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        timeCreate = Date()
        defaultCurrencyName = try container.decode(String.self, forKey: .defaultCurrency)
    }
}
