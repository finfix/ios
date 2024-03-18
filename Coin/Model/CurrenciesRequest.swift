//
//  CurrenciesRequest.swift
//  Coin
//
//  Created by Илья on 16.03.2024.
//

import Combine
import GRDB
import GRDBQuery

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

