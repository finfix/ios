//
//  LocalDatabase.swift
//  Coin
//
//  Created by Илья on 14.05.2024.
//

import Foundation
import GRDB
import Combine

struct LocalDatabase {

    private let writer: DatabaseWriter

    init(_ writer: DatabaseWriter) throws {
        self.writer = writer
        try migrator.migrate(writer)
    }

    var reader: DatabaseReader {
        writer
    }
}

// MARK: - Writes
extension LocalDatabase {
    func importCurrencies(_ currencies: [Currency]) async throws {
        try await writer.write { db in
            for currency in currencies {
                try currency.insert(db)
            }
        }
    }
}

// MARK: - Observe
extension LocalDatabase {
    func observeCurrencies() -> AnyPublisher<[Currency], Error> {

        let observation = ValueObservation.tracking { db in
            return try Currency.fetchAll(db)
        }

        let publisher = observation.publisher(in: reader)
        return publisher.eraseToAnyPublisher()
    }
}
