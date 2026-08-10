//
//  AuditLogModels.swift
//  Coin
//

import Foundation

struct GetAuditLogsReq: Codable {
    var accountGroupID: UUID?
    var entity: AuditLogEntity?
    var method: AuditLogMethod?
    var entityID: String?
    var limit: UInt32?
    var offset: UInt32?
}

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
