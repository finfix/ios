//
//  SyncAPI.swift
//  Coin
//

import Foundation
import OSLog
import ProtoDefinitions
import GRPCCore
import GRPCProtobuf
import GRPCNIOTransportHTTP2
import SwiftProtobuf

private let logger = Logger(subsystem: "Coin", category: "gRPC")

extension Sync_SyncRequest {
    init(sinceID: UInt32) {
        self.init()
        self.sinceID = sinceID
    }
}

extension Sync_ConfirmSyncRequest {
    init(pendingSyncToken: UUID) {
        self.init()
        self.pendingSyncToken = pendingSyncToken.data
    }
}

extension Sync_SubscribeToSyncRequest {
    init(accessToken: String) {
        self.init()
        self.accessToken = accessToken
    }
}

extension APIManager {

    func Sync(req: SyncReq) async throws -> SyncRes {

        let request = Sync_SyncRequest(sinceID: req.sinceID)

        let response = try await grpcCall("Sync", request: request) {
            try await syncClient.sync($0)
        }

        return SyncRes(
            pendingCheckpoint: response.pendingCheckpoint,
            pendingSyncToken: response.hasChanges_p ? try response.pendingSyncToken.toUUID() : nil,
            hasChanges: response.hasChanges_p,
            changedTransactions: try response.changedTransactions.map { transaction in
                GetTransactionsRes(
                    id: try transaction.id.toUUID(),
                    accountingInCharts: transaction.accountingInCharts,
                    amountFrom: Decimal(transaction.amountFrom),
                    amountTo: Decimal(transaction.amountTo),
                    dateTransaction: transaction.dateTransaction.toDate(),
                    isExecuted: transaction.isExecuted,
                    note: transaction.note,
                    type: try TransactionType(from: transaction.type),
                    accountFromID: try transaction.accountFromID.toUUID(),
                    accountToID: try transaction.accountToID.toUUID(),
                    datetimeCreate: transaction.datetimeCreate.toDate(),
                    accountGroupID: try transaction.accountGroupID.toUUID()
                )
            },
            deletedTransactionIDs: try response.deletedTransactionIds.map { try $0.toUUID() },
            changedAccounts: try response.changedAccounts.map { account in
                GetAccountsRes(
                    id: try account.id.toUUID(),
                    accountingInHeader: account.accountingInHeader,
                    accountingInCharts: account.accountingInCharts,
                    iconID: try account.iconID.toUUID(),
                    name: account.name,
                    remainder: Decimal(account.remainder),
                    type: try AccountType(from: account.type),
                    visible: account.visible,
                    parentAccountID: account.parentAccountID != Data() ? try account.parentAccountID.toUUID() : nil,
                    currency: account.currency,
                    accountGroupID: try account.accountGroupID.toUUID(),
                    rank: account.rank,
                    isParent: account.isParent,
                    datetimeCreate: account.datetimeCreate.toDate(),
                    linkedAccountID: account.hasLinkedAccountID && account.linkedAccountID != Data() ? try account.linkedAccountID.toUUID() : nil
                )
            },
            deletedAccountIDs: try response.deletedAccountIds.map { try $0.toUUID() },
            changedAccountGroups: try response.changedAccountGroups.map { accountGroup in
                GetAccountGroupsRes(
                    id: try accountGroup.id.toUUID(),
                    name: accountGroup.name,
                    currency: accountGroup.currency,
                    serialNumber: accountGroup.serialNumber,
                    datetimeCreate: accountGroup.datetimeCreate.toDate()
                )
            },
            deletedAccountGroupIDs: try response.deletedAccountGroupIds.map { try $0.toUUID() },
            changedTags: try response.changedTags.map { tag in
                GetTagsRes(
                    id: try tag.id.toUUID(),
                    name: tag.name,
                    accountGroupID: try tag.accountGroupID.toUUID(),
                    datetimeCreate: tag.datetimeCreate.toDate()
                )
            },
            deletedTagIDs: try response.deletedTagIds.map { try $0.toUUID() },
            changedAccountBudgets: try response.changedAccountBudgets.map { budget in
                GetAccountBudgetsRes(
                    id: try budget.id.toUUID(),
                    accountID: try budget.accountID.toUUID(),
                    amount: Decimal(budget.amount),
                    fixedSum: Decimal(budget.fixedSum),
                    daysOffset: Int8(budget.daysOffset),
                    gradualFilling: budget.gradualFilling,
                    effectiveFrom: budget.effectiveFrom.toDate(),
                    createdByUserID: try budget.createdByUserID.toUUID(),
                    datetimeCreate: budget.datetimeCreate.toDate(),
                    accountGroupID: try budget.accountGroupID.toUUID()
                )
            },
            changedPendingLinkedTransfers: try response.changedPendingLinkedTransfers.map { transfer in
                GetPendingLinkedTransfersRes(
                    id: try transfer.id.toUUID(),
                    status: try PendingLinkedTransferStatus(from: transfer.status),
                    sourceTransactionID: try transfer.sourceTransactionID.toUUID(),
                    sourceAccountID: try transfer.sourceAccountID.toUUID(),
                    targetAccountID: try transfer.targetAccountID.toUUID(),
                    accountGroupID: try transfer.accountGroupID.toUUID()
                )
            },
            deletedPendingLinkedTransferIDs: try response.deletedPendingLinkedTransferIds.map { try $0.toUUID() },
            changedUser: response.hasChangedUser ? GetUserRes(
                id: try response.changedUser.id.toUUID(),
                name: response.changedUser.name,
                email: response.changedUser.email,
                defaultCurrency: response.changedUser.defaultCurrency
            ) : nil,
            changedCurrencies: response.changedCurrencies.map { currency in
                GetCurrenciesRes(
                    isoCode: currency.isoCode,
                    rate: Decimal(currency.rate),
                    name: currency.name,
                    symbol: currency.symbol
                )
            }
        )
    }

    func ConfirmSync(req: ConfirmSyncReq) async throws {

        let request = Sync_ConfirmSyncRequest(pendingSyncToken: req.pendingSyncToken)

        _ = try await grpcCall("ConfirmSync", request: request) {
            try await syncClient.confirmSync($0)
        }
    }

    /// Держит server-streaming RPC открытым и присылает событие в стрим на каждый
    /// SyncNotification от бэкенда — чисто сигнал "дёрни Sync/incrementalSync", без payload (см.
    /// SubscribeToSync в sync-endpoint.proto). Живёт, пока вызывающий код итерирует
    /// AsyncThrowingStream — отмена (Task.cancel()/выход из for-await) рвёт сам gRPC-стрим через
    /// continuation.onTermination.
    func SubscribeToSync() -> AsyncThrowingStream<Void, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                logger.debug("→ SubscribeToSync")
                do {
                    let accessToken = try await authManager.getAccessToken()
                    let request = Sync_SubscribeToSyncRequest(accessToken: accessToken)
                    try await syncClient.subscribeToSync(request) { response in
                        for try await _ in response.messages {
                            logger.debug("← SubscribeToSync: получено уведомление")
                            continuation.yield(())
                        }
                        logger.debug("SubscribeToSync: стрим сервера закрылся штатно")
                    }
                    continuation.finish()
                } catch {
                    logger.error("✗ SubscribeToSync: \(String(describing: error), privacy: .public)")
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { reason in
                logger.debug("SubscribeToSync: onTermination — \(String(describing: reason), privacy: .public)")
                task.cancel()
            }
        }
    }
}
