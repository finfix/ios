//
//  TagToTransactionDB.swift
//  Coin
//
//  Created by Илья on 20.04.2024.
//

import Foundation
import GRDB

struct TagToTransactionDB {
    
    var transactionId: UInt32
    var tagId: UInt32
    
    init(
        transactionID: UInt32,
        tagID: UInt32
    ) {
        self.transactionId = transactionID
        self.tagId = tagID
    }
    
    // Инициализатор из сетевой модели
    init(_ res: GetTagsToTransactionsRes) {
        self.transactionId = res.transactionID
        self.tagId = res.tagID
    }
    
    static func convertFromApiModel(_ icons: [GetTagsToTransactionsRes]) -> [TagToTransactionDB] {
        var iconsDB: [TagToTransactionDB] = []
        for icon in icons {
            iconsDB.append(TagToTransactionDB(icon))
        }
        return iconsDB
    }
}

// MARK: - Persistence
extension TagToTransactionDB: Codable, FetchableRecord, PersistableRecord {
    enum Columns {
        static let transactionId = Column(CodingKeys.transactionId)
        static let tagId = Column(CodingKeys.tagId)
    }
}

