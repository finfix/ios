//
//  Currencies.swift
//  Coin
//
//  Created by Илья on 21.10.2023.
//

import Foundation
import Combine
import GRDB
import GRDBQuery

struct Currency {
    
    var code: String
    var name: String
    var rate: Decimal
    var symbol: String
    
    init(
        code: String = "",
        name: String = "",
        rate: Decimal = 1,
        symbol: String = ""
    ) {
        self.code = code
        self.name = name
        self.rate = rate
        self.symbol = symbol
    }
    
    init(_ res: GetCurrenciesRes) {
        self.code = res.isoCode
        self.name = res.name
        self.symbol = res.symbol
        self.rate = res.rate
    }
}


extension Currency: Hashable {
    static func == (lhs: Currency, rhs: Currency) -> Bool {
        return lhs.code == rhs.code
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

// MARK: - Persistence
extension Currency: Codable, FetchableRecord, PersistableRecord {
    fileprivate enum Columns {
        static let code = Column(CodingKeys.code)
        static let name = Column(CodingKeys.name)
        static let rate = Column(CodingKeys.rate)
        static let symbol = Column(CodingKeys.symbol)
    }
}

// MARK: - Currency Database Requests
extension DerivableRequest<Currency> {
    func orderedByCode() -> Self {
        order(
            Currency.Columns.code.desc
        )
    }
}

// MARK: - Currency @Query
struct CurrencyRequest: Queryable {
    enum Ordering {
        case byCode
    }
    
    var ordering: Ordering
    
    // MARK: - Queryable Implementation
    
    static var defaultValue: [Currency] { [] }
    
    func publisher(in appDatabase: AppDatabase) -> AnyPublisher<[Currency], Error> {
        ValueObservation
            .tracking(fetchValue(_:))
            .publisher(
                in: appDatabase.reader,
                scheduling: .immediate)
            .eraseToAnyPublisher()
    }
    
    func fetchValue(_ db: Database) throws -> [Currency] {
        return try Currency.all().fetchAll(db)
    }
}
