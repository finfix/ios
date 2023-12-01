//
//  AccountGroup.swift
//  Coin
//
//  Created by Илья on 19.10.2023.
//

import Foundation
import SwiftData

@Model class AccountGroup {
    
    @Attribute(.unique) var id: UInt32
    var name: String
    var currency: Currency?
        
    init(
        id: UInt32 = 0,
        name: String = "",
        currency: Currency? = nil
    ) {
        self.id = id
        self.name = name
        self.currency = currency
    }
    
    init(_ res: GetAccountGroupsRes, currenciesMap: [String: Currency]) {
        self.id = res.id
        self.name = res.name
        self.currency = currenciesMap[res.currency]
    }
}
