//
//  SyncAPI.swift
//  Coin
//

import Foundation
import ProtoDefinitions
import GRPCCore
import GRPCProtobuf
import GRPCNIOTransportHTTP2
import SwiftProtobuf

extension APIManager {

    func Sync(req: SyncReq) async throws -> SyncRes {

        let accessToken = try await self.networkManager.authManager.getAccessToken()

        let request = Sync_SyncRequest.with {
            $0.accessToken = accessToken
            $0.sinceID = req.sinceID
        }

        let response = try await grpcCall("Sync", request: request) {
            try await syncClient.sync($0)
        }

        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage, code: response.error.code)
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
                    datetimeCreate: account.datetimeCreate.toDate()
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

        let accessToken = try await self.networkManager.authManager.getAccessToken()

        let request = Sync_ConfirmSyncRequest.with {
            $0.accessToken = accessToken
            $0.pendingSyncToken = req.pendingSyncToken.data
        }

        let response = try await grpcCall("ConfirmSync", request: request) {
            try await syncClient.confirmSync($0)
        }

        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage, code: response.error.code)
        }
    }
}
