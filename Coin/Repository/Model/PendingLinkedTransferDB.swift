//
//  PendingLinkedTransferDB.swift
//  Coin
//

import Foundation
import GRDB

struct PendingLinkedTransferDB {

    var id: UUID?
    var status: PendingLinkedTransferStatus
    var sourceTransactionID: UUID
    var sourceAccountID: UUID
    var targetAccountID: UUID
    var accountGroupID: UUID

    init(
        id: UUID,
        status: PendingLinkedTransferStatus,
        sourceTransactionID: UUID,
        sourceAccountID: UUID,
        targetAccountID: UUID,
        accountGroupID: UUID
    ) {
        self.id = id
        self.status = status
        self.sourceTransactionID = sourceTransactionID
        self.sourceAccountID = sourceAccountID
        self.targetAccountID = targetAccountID
        self.accountGroupID = accountGroupID
    }

    // Инициализатор из сетевой модели
    init(_ res: GetPendingLinkedTransfersRes) {
        self.id = res.id
        self.status = res.status
        self.sourceTransactionID = res.sourceTransactionID
        self.sourceAccountID = res.sourceAccountID
        self.targetAccountID = res.targetAccountID
        self.accountGroupID = res.accountGroupID
    }

    // Инициализатор из бизнес-модели
    init(_ model: PendingLinkedTransfer) {
        self.id = model.id
        self.status = model.status
        self.sourceTransactionID = model.sourceTransactionID
        self.sourceAccountID = model.sourceAccountID
        self.targetAccountID = model.targetAccountID
        self.accountGroupID = model.accountGroupID
    }

    static func convertFromApiModel(_ transfers: [GetPendingLinkedTransfersRes]) -> [PendingLinkedTransferDB] {
        transfers.map { PendingLinkedTransferDB($0) }
    }
}

// MARK: - Persistence
extension PendingLinkedTransferDB: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "pendingLinkedTransferDB"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let status = Column(CodingKeys.status)
        static let sourceTransactionID = Column(CodingKeys.sourceTransactionID)
        static let sourceAccountID = Column(CodingKeys.sourceAccountID)
        static let targetAccountID = Column(CodingKeys.targetAccountID)
        static let accountGroupID = Column(CodingKeys.accountGroupID)
    }
}
