//
//  AccountGroup.swift
//  Coin
//
//  Created by Илья on 19.10.2023.
//

import Foundation
import SwiftData

@Model class AccountGroup: Decodable {
    
    @Attribute(.unique) var id: UInt32
    var name: String
    var currencyName: String
    var currency: Currency?
    
    init(id: UInt32 = 0, name: String = "", currency: String = "USD") {
        self.id = id
        self.name = name
        self.currencyName = currency
    }
    
    private enum CodingKeys: CodingKey {
        case id, name, currency
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UInt32.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        currencyName = try container.decode(String.self, forKey: .currency)
    }
    
    func getByID(_ id: UInt32, context: ModelContext) -> AccountGroup {
        let descriptor = FetchDescriptor<AccountGroup>(predicate: #Predicate { $0.id == id })
        let accountGroups = (try? context.fetch(descriptor)) ?? []
        if let accountGroup = accountGroups.first {
            return accountGroup
        }
        return AccountGroup()
    }
}
