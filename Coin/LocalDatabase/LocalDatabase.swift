//
//  LocalDatabase.swift
//  Coin
//
//  Created by Илья on 14.05.2024.
//

import Foundation
import GRDB

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
