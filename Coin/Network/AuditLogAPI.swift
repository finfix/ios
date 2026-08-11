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

extension APIManager {

    func GetAuditLogs(req: GetAuditLogsReq) async throws -> [GetAuditLogsRes] {

        let accessToken = try await self.networkManager.authManager.getAccessToken()

        let request = try AuditLog_GetAuditLogsRequest.with {
            $0.accessToken = accessToken
            if let accountGroupID = req.accountGroupID {
                $0.accountGroupID = accountGroupID.data
            }
            if let entity = req.entity {
                $0.entity = try entity.toProto()
            }
            if let method = req.method {
                $0.method = try method.toProto()
            }
            if let entityID = req.entityID {
                $0.entityID = entityID
            }
            if let limit = req.limit {
                $0.limit = limit
            }
            if let offset = req.offset {
                $0.offset = offset
            }
        }

        let response = try await grpcCall("GetAuditLogs", request: request) {
            try await auditLogClient.getAuditLogs($0)
        }

        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage, code: response.error.code)
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
