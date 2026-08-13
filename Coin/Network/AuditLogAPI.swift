//
//  AuditLogAPI.swift
//  Coin
//

import Foundation
import ProtoDefinitions
import GRPCCore
import GRPCProtobuf
import GRPCNIOTransportHTTP2
import SwiftProtobuf

extension AuditLog_GetAuditLogsRequest {
    init(
        accountGroupID: UUID?,
        entity: AuditLogEntity?,
        method: AuditLogMethod?,
        entityID: String?,
        limit: UInt32?,
        offset: UInt32?
    ) throws {
        self.init()
        if let accountGroupID {
            self.accountGroupID = accountGroupID.data
        }
        if let entity {
            self.entity = try entity.toProto()
        }
        if let method {
            self.method = try method.toProto()
        }
        if let entityID {
            self.entityID = entityID
        }
        if let limit {
            self.limit = limit
        }
        if let offset {
            self.offset = offset
        }
    }
}

extension APIManager {

    func GetAuditLogs(req: GetAuditLogsReq) async throws -> [GetAuditLogsRes] {

        let request = try AuditLog_GetAuditLogsRequest(
            accountGroupID: req.accountGroupID,
            entity: req.entity,
            method: req.method,
            entityID: req.entityID,
            limit: req.limit,
            offset: req.offset
        )

        let response = try await grpcCall("GetAuditLogs", request: request) {
            try await auditLogClient.getAuditLogs($0)
        }

        return try response.auditLogs.map { auditLog in
            GetAuditLogsRes(
                id: auditLog.id,
                entity: try AuditLogEntity(from: auditLog.entity),
                method: try AuditLogMethod(from: auditLog.method),
                entityID: auditLog.entityID,
                snapshotBefore: auditLog.hasSnapshotBefore ? auditLog.snapshotBefore : nil,
                snapshotAfter: auditLog.hasSnapshotAfter ? auditLog.snapshotAfter : nil,
                userID: try auditLog.userID.toUUID(),
                deviceID: auditLog.deviceID,
                accountGroupID: try auditLog.hasAccountGroupID ? auditLog.accountGroupID.toUUID() : nil,
                datetimeCreate: auditLog.datetimeCreate.toDate()
            )
        }
    }
}
