//
//  User.swift
//  Coin
//
//  Created by Илья on 30.10.2023.
//

import Foundation
import Combine
import GRDB
import GRDBQuery

struct User: Identifiable {
    
    var id: UInt32
    var name: String
    var email: String
    var defaultCurrencyCode: String
    
    init(
        id: UInt32 = 0,
        name: String = "",
        email: String = "",
        defaultCurrencyCode: String = ""
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.defaultCurrencyCode = defaultCurrencyCode
    }
    
    init(_ res: GetUserRes) {
        self.id = res.id
        self.name = res.name
        self.email = res.email
        self.defaultCurrencyCode = res.defaultCurrency
    }
}

// MARK: - belongs
extension User {
    static let currency = belongsTo(Currency.self)
    var currency: QueryInterfaceRequest<Currency> {
        request(for: User.currency)
    }
}

// MARK: - Persistence
extension User: Codable, FetchableRecord, PersistableRecord {
    fileprivate enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let email = Column(CodingKeys.email)
        static let defaultCurrencyCode = Column(CodingKeys.defaultCurrencyCode)
    }
}

// MARK: - User @Query
struct UserRequest: Queryable {
    
    // MARK: - Queryable Implementation
    
    static var defaultValue: [User] { [] }
    
    func publisher(in appDatabase: AppDatabase) -> AnyPublisher<[User], Error> {
        ValueObservation
            .tracking(fetchValue(_:))
            .publisher(
                in: appDatabase.reader,
                scheduling: .immediate)
            .eraseToAnyPublisher()
    }
    
    func fetchValue(_ db: Database) throws -> [User] {
        return try User.all().fetchAll(db)
    }
}
