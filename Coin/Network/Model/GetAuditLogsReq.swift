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
