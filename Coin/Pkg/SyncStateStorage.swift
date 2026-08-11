//
//  SyncStateStorage.swift
//  Coin
//

import Foundation

/// Чекпоинт инкрементальной синхронизации (Sync/ConfirmSync) — не секрет, поэтому, в отличие
/// от AuthStorage, хранится в обычном UserDefaults, а не в Keychain.
@Observable
final class SyncStateStorage {

    static let shared = SyncStateStorage()

    private enum Keys {
        static let lastSyncedAuditLogID = "lastSyncedAuditLogID"
    }

    var lastSyncedAuditLogID: UInt32 {
        didSet {
            UserDefaults.standard.set(lastSyncedAuditLogID, forKey: Keys.lastSyncedAuditLogID)
        }
    }

    private init() {
        self.lastSyncedAuditLogID = UInt32(UserDefaults.standard.integer(forKey: Keys.lastSyncedAuditLogID))
    }
}
