//
//  AuditLogModels.swift
//  Coin
//

import Foundation

struct GetAuditLogsRes: Decodable {
    let id: UInt32
    let entity: AuditLogEntity
    let method: AuditLogMethod
    let entityID: String
    let snapshotBefore: Data?
    let snapshotAfter: Data?
    let userID: UUID
    let deviceID: String
    let accountGroupID: UUID?
    let datetimeCreate: Date
}
