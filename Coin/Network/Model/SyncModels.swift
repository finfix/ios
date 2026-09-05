//
//  SyncModels.swift
//  Coin
//

import Foundation

struct SyncReq: Codable {
    var sinceID: UInt32
}

struct SyncRes {
    var pendingCheckpoint: UInt32
    var pendingSyncToken: UUID?
    var hasChanges: Bool

    var changedTransactions: [GetTransactionsRes]
    var deletedTransactionIDs: [UUID]

    var changedAccounts: [GetAccountsRes]
    var deletedAccountIDs: [UUID]

    var changedAccountGroups: [GetAccountGroupsRes]
    var deletedAccountGroupIDs: [UUID]

    var changedTags: [GetTagsRes]
    var deletedTagIDs: [UUID]

    var changedAccountBudgets: [GetAccountBudgetsRes]

    var changedPendingLinkedTransfers: [GetPendingLinkedTransfersRes]
    var deletedPendingLinkedTransferIDs: [UUID]

    var changedUser: GetUserRes?

    var changedCurrencies: [GetCurrenciesRes]
}

struct ConfirmSyncReq: Codable {
    var pendingSyncToken: UUID
}
