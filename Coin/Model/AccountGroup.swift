//
//  AccountGroup.swift
//  Coin
//
//  Created by Илья on 19.10.2023.
//

import Foundation
import SwiftData

@Model class AccountGroup: Decodable, Identifiable {
    
    @Attribute(.unique) var id: UInt32
    var name: String
    var currency: String
    
    init(id: UInt32 = 0, name: String = "", currency: String = "USD") {
        self.id = id
        self.name = name
        self.currency = currency
    }
    
    private enum CodingKeys: CodingKey {
        case id, name, currency
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UInt32.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        currency = try container.decode(String.self, forKey: .currency)
    }
}

extension AccountGroup: Hashable {
    
    static func == (lhs: AccountGroup, rhs: AccountGroup) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
