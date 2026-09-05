//
//  PendingLinkedTransferModels.swift
//  Coin
//

import Foundation

struct CreatePendingLinkedTransferReq: Codable {
    var id: UUID
    var sourceTransactionID: UUID
    var sourceAccountID: UUID
    var targetAccountID: UUID
    var accountGroupID: UUID

    init(
        id: UUID = UUID(),
        sourceTransactionID: UUID,
        sourceAccountID: UUID,
        targetAccountID: UUID,
        accountGroupID: UUID
    ) {
        self.id = id
        self.sourceTransactionID = sourceTransactionID
        self.sourceAccountID = sourceAccountID
        self.targetAccountID = targetAccountID
        self.accountGroupID = accountGroupID
    }
}
