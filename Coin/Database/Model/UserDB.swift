//
//  User.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation
import GRDB

struct UserDB {
    
    var id: UInt32
    var name: String
    var email: String
    var defaultCurrencyCode: String
    
    // Инициализатор из сетевой модели
    init(_ res: GetUserRes) {
        self.id = res.id
        self.name = res.name
        self.email = res.email
        self.defaultCurrencyCode = res.defaultCurrency
    }
}

// MARK: - Persistence
extension UserDB: Codable, FetchableRecord, PersistableRecord {
    fileprivate enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let email = Column(CodingKeys.email)
        static let defaultCurrencyCode = Column(CodingKeys.defaultCurrencyCode)
    }
}
