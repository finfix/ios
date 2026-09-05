//
//  AuditLog.swift
//  Coin
//

import Foundation

enum AuditLogEntity: String, Codable {
    case transaction, account, accountGroup, tag, user, currency
}
