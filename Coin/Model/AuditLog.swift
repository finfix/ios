//
//  AuditLog.swift
//  Coin
//

import Foundation

enum AuditLogEntity: String, Codable {
    case transaction, account, accountGroup, tag, user, currency
}

enum AuditLogMethod: String, Codable {
    case create, update, delete
}

struct AuditLog: Identifiable, Hashable {
    var id: UInt32
    var entity: AuditLogEntity
    var method: AuditLogMethod
    var entityID: String
    var snapshotBefore: Data?
    var snapshotAfter: Data?
    var userID: UUID
    var deviceID: String
    var accountGroupID: UUID?
    var datetimeCreate: Date

    init(_ res: GetAuditLogsRes) {
        self.id = res.id
        self.entity = res.entity
        self.method = res.method
        self.entityID = res.entityID
        self.snapshotBefore = res.snapshotBefore
        self.snapshotAfter = res.snapshotAfter
        self.userID = res.userID
        self.deviceID = res.deviceID
        self.accountGroupID = res.accountGroupID
        self.datetimeCreate = res.datetimeCreate
    }

    static func convertFromApiModel(_ res: [GetAuditLogsRes]) -> [AuditLog] {
        res.map { AuditLog($0) }
    }

    /// Красиво отформатированный JSON слепка (before/after) для показа в UI.
    private static func prettyPrint(_ data: Data?) -> String? {
        guard let data,
              let object = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: prettyData, encoding: .utf8) else {
            return nil
        }
        return string
    }

    var snapshotBeforePretty: String? { Self.prettyPrint(snapshotBefore) }
    var snapshotAfterPretty: String? { Self.prettyPrint(snapshotAfter) }
}
