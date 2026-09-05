//
//  SyncModels.swift
//  Coin
//

import Foundation

struct ConfirmSyncReq: Codable {
    var pendingSyncToken: UUID
}
