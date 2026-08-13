//
//  TransactionAPI.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import ProtoDefinitions
import GRPCCore
import GRPCProtobuf
import GRPCNIOTransportHTTP2
import Foundation
import SwiftProtobuf

extension Transaction_GetTransactionsRequest {
    init(
        accountID: UUID?,
        dateFrom: Date,
        dateTo: Date,
        type: String?,
        offset: UInt32?,
        limit: UInt8?
    ) throws {
        self.init()
        self.accountID = accountID.dataOrEmpty
        self.accountGroupIds = []
        self.dateFrom = Google_Protobuf_Timestamp(localFilter: dateFrom)
        self.dateTo = Google_Protobuf_Timestamp(localFilter: dateTo)
        if let type {
            guard let transactionType = TransactionType(rawValue: type) else {
                throw ErrorModel(humanText: "Неизвестный тип транзакции: \(type)")
            }
            self.type = try transactionType.toProto()
        }
        if let offset {
            self.offset = offset
        }
        if let limit {
            self.limit = UInt32(limit)
        }
    }
}

extension Transaction_CreateTransactionRequest {
    init(
        id: UUID,
        accountFromID: UUID,
        accountToID: UUID,
        amountFrom: Decimal,
        amountTo: Decimal,
        dateTransaction: Date,
        note: String,
        type: String,
        isExecuted: Bool,
        tagIDs: [UUID],
        datetimeCreate: Date,
        accountingInCharts: Bool,
        accountGroupID: UUID
    ) throws {
        self.init()
        self.id = id.data
        self.accountFromID = accountFromID.data
        self.accountToID = accountToID.data
        self.amountFrom = amountFrom.doubleValue
        self.amountTo = amountTo.doubleValue
        self.dateTransaction = Google_Protobuf_Timestamp(dateTransaction)
        self.note = note
        guard let transactionType = TransactionType(rawValue: type) else {
            throw ErrorModel(humanText: "Неизвестный тип транзакции: \(type)")
        }
        self.type = try transactionType.toProto()
        self.isExecuted = isExecuted
        self.tagIds = tagIDs.map { $0.data }
        self.datetimeCreate = Google_Protobuf_Timestamp(datetimeCreate)
        self.accountingInCharts = accountingInCharts
        self.accountGroupID = accountGroupID.data
    }
}

extension Transaction_UpdateTransactionRequest {
    init(
        id: UUID,
        accountFromID: UUID?,
        accountToID: UUID?,
        amountFrom: Decimal?,
        amountTo: Decimal?,
        dateTransaction: Date?,
        note: String?,
        tagIDs: [UUID]?,
        accountingInCharts: Bool?
    ) {
        self.init()
        self.id = id.data
        if let accountFromID {
            self.accountFromID = accountFromID.data
        }
        if let accountToID {
            self.accountToID = accountToID.data
        }
        if let amountFrom {
            self.amountFrom = amountFrom.doubleValue
        }
        if let amountTo {
            self.amountTo = amountTo.doubleValue
        }
        if let dateTransaction {
            self.dateTransaction = Google_Protobuf_Timestamp(dateTransaction)
        }
        if let note {
            self.note = note
        }
        if let tagIDs {
            self.tagIds = tagIDs.map { $0.data }
        }
        if let accountingInCharts {
            self.accountingInCharts = accountingInCharts
        }
    }
}

extension Transaction_DeleteTransactionRequest {
    init(id: UUID) {
        self.init()
        self.id = id.data
    }
}

extension APIManager {

    func GetTransactions(req: GetTransactionReq) async throws -> [GetTransactionsRes] {

        let request = try Transaction_GetTransactionsRequest(
            accountID: req.accountID,
            dateFrom: req.dateFrom,
            dateTo: req.dateTo,
            type: req.type,
            offset: req.offset,
            limit: req.limit
        )

        let response = try await grpcCall("GetTransactions", request: request) {
            try await transactionClient.getTransactions($0)
        }

        return try response.transactions.map { transaction in
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
        }
    }

    func CreateTransaction(req: CreateTransactionReq) async throws {

        let request = try Transaction_CreateTransactionRequest(
            id: req.id,
            accountFromID: req.accountFromID,
            accountToID: req.accountToID,
            amountFrom: req.amountFrom,
            amountTo: req.amountTo,
            dateTransaction: req.dateTransaction,
            note: req.note,
            type: req.type,
            isExecuted: req.isExecuted,
            tagIDs: req.tagIDs,
            datetimeCreate: req.datetimeCreate,
            accountingInCharts: req.accountingInCharts,
            accountGroupID: req.accountGroupID
        )

        _ = try await grpcCall("CreateTransaction", request: request) {
            try await transactionClient.createTransaction($0)
        }
    }

    func UpdateTransaction(req: UpdateTransactionReq) async throws {

        let request = Transaction_UpdateTransactionRequest(
            id: req.id,
            accountFromID: req.accountFromID,
            accountToID: req.accountToID,
            amountFrom: req.amountFrom,
            amountTo: req.amountTo,
            dateTransaction: req.dateTransaction,
            note: req.note,
            tagIDs: req.tagIDs,
            accountingInCharts: req.accountingInCharts
        )

        _ = try await grpcCall("UpdateTransaction", request: request) {
            try await transactionClient.updateTransaction($0)
        }
    }

    func DeleteTransaction(req: DeleteTransactionReq) async throws {

        let request = Transaction_DeleteTransactionRequest(id: req.id)

        _ = try await grpcCall("DeleteTransaction", request: request) {
            try await transactionClient.deleteTransaction($0)
        }
    }
}
