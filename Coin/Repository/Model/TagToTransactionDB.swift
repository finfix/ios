//
//  TagToTransactionDB.swift
//  Coin
//
//  Created by Илья on 20.04.2024.
//

import Foundation
import GRDB

struct TagToTransactionDB {
    
    var transactionId: UUID
    var tagId: UUID
    
    init(
        transactionID: UUID,
        tagID: UUID
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
    
    static func compareTwoArrays(_ serverModels: [TagToTransactionDB], _ localModels: [TagToTransactionDB]) -> [UUID: [String: (server: Any, local: Any)]] {
        let serverModels = serverModels.sorted { ($0.transactionId, $0.tagId) < ($1.transactionId, $1.tagId) }
        let localModels = localModels.sorted { ($0.transactionId, $0.tagId) < ($1.transactionId, $1.tagId) }
        
        var differences: [UUID: [String: (server: Any, local: Any)]] = [:]
        
        guard serverModels.count == localModels.count else {
            var difference: [String: (server: Any, local: Any)] = ["count": (server: serverModels.count, local: localModels.count)]
            differences[UUID(uuid: UUID_NULL)] = difference
            return differences
        }
        
        for (i, serverModel) in serverModels.enumerated() {
            var difference: [String: (server: Any, local: Any)] = [:]
            if serverModel.transactionId != localModels[i].transactionId {
                difference["transactionId"] = (server: serverModel.transactionId, local: localModels[i].transactionId)
            }
            if serverModel.tagId != localModels[i].tagId {
                difference["tagId"] = (server: serverModel.tagId, local: localModels[i].tagId)
            }
            if !difference.isEmpty {
                differences[UUID()] = difference
            }
        }
        return differences
    }
}

// MARK: - Persistence
extension TagToTransactionDB: Codable, FetchableRecord, PersistableRecord {
    enum Columns {
        static let transactionId = Column(CodingKeys.transactionId)
        static let tagId = Column(CodingKeys.tagId)
    }
}

