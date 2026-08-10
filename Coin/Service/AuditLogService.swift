//
//  AuditLogService.swift
//  Coin
//

import Foundation

extension Service {

    // MARK: Read
    func getAuditLogs(
        accountGroupID: UUID? = nil,
        entity: AuditLogEntity? = nil,
        method: AuditLogMethod? = nil,
        entityID: String? = nil,
        limit: UInt32? = nil,
        offset: UInt32? = nil
    ) async throws -> [AuditLog] {
        let res = try await apiManager.GetAuditLogs(req: GetAuditLogsReq(
            accountGroupID: accountGroupID,
            entity: entity,
            method: method,
            entityID: entityID,
            limit: limit,
            offset: offset
        ))
        return AuditLog.convertFromApiModel(res)
    }
}
