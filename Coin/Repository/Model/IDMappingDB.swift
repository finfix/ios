//
//  IDMappingDB.swift
//  Coin
//
//  Created by Илья on 07.05.2024.
//

import Foundation
import GRDB

struct IDMappingDB {
    
    var localID: UInt32
    var serverID: UInt32?
    var modelType: ModelType
    
    static func getMapForModelType(mapping: [IDMappingDB], modelType: ModelType) -> [UInt32: UInt32] {
        return Dictionary(uniqueKeysWithValues: mapping.filter{$0.modelType == modelType}.map { ( $0.localID, $0.serverID! ) } )
    }
}

// MARK: - Persistence
extension IDMappingDB: Codable, FetchableRecord, PersistableRecord {
    enum Columns {
        static let localID = Column(CodingKeys.localID)
        static let serverID = Column(CodingKeys.serverID)
        static let modelType = Column(CodingKeys.modelType)
    }
}

