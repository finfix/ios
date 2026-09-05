//
//  PendingLinkedTransferModels.swift
//  Coin
//

import Foundation

struct GetPendingLinkedTransfersRes: Decodable {
    var id: UUID
    var status: PendingLinkedTransferStatus
    var sourceTransactionID: UUID
    var sourceAccountID: UUID
    var targetAccountID: UUID
    var accountGroupID: UUID
}
