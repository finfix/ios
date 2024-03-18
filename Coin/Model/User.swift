//
//  User.swift
//  Coin
//
//  Created by Илья on 30.10.2023.
//

import Foundation
import GRDB

struct User: Identifiable {
    
    var id: UInt32
    var name: String
    var email: String
    var defaultCurrencyCode: String
    
    init(
        id: UInt32 = 0,
        name: String = "",
        email: String = "",
        defaultCurrency: String = ""
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.defaultCurrencyCode = defaultCurrency
    }
    
    init(_ res: GetUserRes) {
        self.id = res.id
        self.name = res.name
        self.email = res.email
        self.defaultCurrencyCode = res.defaultCurrency
    }
}

// MARK: - Persistence

extension User: Codable, FetchableRecord {
    fileprivate enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let email = Column(CodingKeys.email)
        static let defaultCurrencyCode = Column(CodingKeys.defaultCurrencyCode)
    }
}
