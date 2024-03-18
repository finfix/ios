//
//  AccountGroup.swift
//  Coin
//
//  Created by Илья on 19.10.2023.
//

import Foundation
import Combine
import GRDB
import GRDBQuery

struct AccountGroup: Identifiable {
    
    var id: UInt32
    var name: String
    var serialNumber: UInt32
    var currencyCode: String
        
    init(
        id: UInt32 = 0,
        name: String = "",
        serialNumber: UInt32 = 0,
        currencyCode: String = ""
    ) {
        self.id = id
        self.name = name
        self.serialNumber = serialNumber
        self.currencyCode = currencyCode
    }
    
    init(_ res: GetAccountGroupsRes) {
        self.id = res.id
        self.name = res.name
        self.serialNumber = res.serialNumber
        self.currencyCode = res.currency
    }
}

extension AccountGroup: Hashable {
    static func == (lhs: AccountGroup, rhs: AccountGroup) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - belongs
extension AccountGroup {
    static let currency = belongsTo(Currency.self)
    var currency: QueryInterfaceRequest<Currency> {
        request(for: AccountGroup.currency)
    }
}

// MARK: - Persistence
extension AccountGroup: Codable, FetchableRecord, PersistableRecord {
    fileprivate enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let currencyCode = Column(CodingKeys.currencyCode)
        static let serialNumber = Column(CodingKeys.serialNumber)
    }
}

// MARK: - Currency Database Requests
extension DerivableRequest<AccountGroup> {
    func orderedBySerialNumber() -> Self {
        order(
            AccountGroup.Columns.serialNumber.asc
        )
    }
}

// MARK: - AccountGroup @Query
struct AccountGroupRequest: Queryable {
    
    enum Ordering {
        case bySerialNumber
    }

    var ordering: Ordering
        
    static var defaultValue: [AccountGroup] { [] }
    
    func publisher(in appDatabase: AppDatabase) -> AnyPublisher<[AccountGroup], Error> {
        ValueObservation
            .tracking(fetchValue(_:))
            .publisher(
                in: appDatabase.reader,
                scheduling: .immediate)
            .eraseToAnyPublisher()
    }
    
    func fetchValue(_ db: Database) throws -> [AccountGroup] {
        switch ordering {
        case .bySerialNumber:
            return try AccountGroup.all().orderedBySerialNumber().fetchAll(db)
        }
    }
}

