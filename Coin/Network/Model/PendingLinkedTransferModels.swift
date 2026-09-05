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

struct GetPendingLinkedTransfersRes: Decodable {
    var id: UUID
    var status: PendingLinkedTransferStatus
    var sourceTransactionID: UUID
    var sourceAccountID: UUID
    var targetAccountID: UUID
    var accountGroupID: UUID
}

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

struct CreatePendingLinkedTransferRes: Decodable {
}

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

struct UpdatePendingLinkedTransferRes: Decodable {
}

struct DeletePendingLinkedTransferReq: Codable {
    var id: UUID
}

struct DeletePendingLinkedTransferRes: Decodable {
}
