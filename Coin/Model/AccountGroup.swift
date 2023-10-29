//
//  AccountGroup.swift
//  Coin
//
//  Created by Илья on 19.10.2023.
//

import Foundation

class AccountGroup: Decodable, Identifiable {
    var id: UInt32
    var name: String
    var currency: String
    
    init(id: UInt32 = 0, name: String = "", currency: String = "USD") {
        self.id = id
        self.name = name
        self.currency = currency
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
