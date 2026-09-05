//
//  PendingLinkedTransferModels.swift
//  Coin
//

import Foundation

struct UpdatePendingLinkedTransferReq: Codable {
    var id: UUID
    var status: PendingLinkedTransferStatus?

    var hasChanges: Bool {
        status != nil
    }

    init(
        id: UUID,
        status: PendingLinkedTransferStatus? = nil
    ) {
        self.id = id
        self.status = status
    }
}
