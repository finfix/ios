//
//  PendingLinkedTransferModels.swift
//  Coin
//

import Foundation

struct GetPendingLinkedTransfersReq: Codable {
    /// Мои группы — вернёт переносы, где я источник.
    var accountGroupIDs: [UUID] = []
    /// Мои счета — вернёт переносы, где я получатель.
    var targetAccountIDs: [UUID] = []
}
