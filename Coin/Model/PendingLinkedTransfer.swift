//
//  PendingLinkedTransfer.swift
//  Coin
//

import Foundation

/// Требование довнесения транзакции через счёт-мост (см. Account.linkedAccountID). Плоская
/// структура-связка — sourceAccountID/targetAccountID/accountGroupID хранятся как id, а не
/// резолвятся в объекты автоматически: targetAccountID может быть моим счётом (я получатель) или
/// нет (я источник), в зависимости от того, с чьей стороны я смотрю на запись.
struct PendingLinkedTransfer: Identifiable, Hashable {
    var id: UUID
    var status: PendingLinkedTransferStatus
    var sourceTransactionID: UUID
    var sourceAccountID: UUID
    var targetAccountID: UUID
    var accountGroupID: UUID

    init(
        id: UUID = UUID(),
        status: PendingLinkedTransferStatus = .pending,
        sourceTransactionID: UUID = UUID(),
        sourceAccountID: UUID = UUID(),
        targetAccountID: UUID = UUID(),
        accountGroupID: UUID = UUID()
    ) {
        self.id = id
        self.status = status
        self.sourceTransactionID = sourceTransactionID
        self.sourceAccountID = sourceAccountID
        self.targetAccountID = targetAccountID
        self.accountGroupID = accountGroupID
    }

    init(_ dbModel: PendingLinkedTransferDB) {
        self.id = dbModel.id!
        self.status = dbModel.status
        self.sourceTransactionID = dbModel.sourceTransactionID
        self.sourceAccountID = dbModel.sourceAccountID
        self.targetAccountID = dbModel.targetAccountID
        self.accountGroupID = dbModel.accountGroupID
    }

    static func convertFromDBModel(_ dbModels: [PendingLinkedTransferDB]) -> [PendingLinkedTransfer] {
        dbModels.map { PendingLinkedTransfer($0) }
    }
}

enum PendingLinkedTransferStatus: String, Codable, CaseIterable {
    case pending, completed, ignored
}
