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

extension APIManager {
    
    func GetTransactions(req: GetTransactionReq) async throws -> [GetTransactionsRes] {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = try Transaction_GetTransactionsRequest.with {
            $0.accessToken = accessToken
            $0.accountID = req.accountID.dataOrEmpty
            $0.accountGroupIds = []
            $0.dateFrom = Google_Protobuf_Timestamp(req.dateFrom)
            $0.dateTo = Google_Protobuf_Timestamp(req.dateTo)
            if let type = req.type {
                guard let transactionType = TransactionType(rawValue: type) else {
                    throw ErrorModel(humanText: "Неизвестный тип транзакции: \(type)")
                }
                $0.type = try transactionType.toProto()
            }
            if let offset = req.offset {
                $0.offset = offset
            }
            if let limit = req.limit {
                $0.limit = UInt32(limit)
            }
        }
        
        let response = try await transactionClient.getTransactions(request)
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
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
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = try Transaction_CreateTransactionRequest.with {
            $0.accessToken = accessToken
            $0.id = req.id.data
            $0.accountFromID = req.accountFromID.data
            $0.accountToID = req.accountToID.data
            $0.amountFrom = req.amountFrom.doubleValue
            $0.amountTo = req.amountTo.doubleValue
            $0.dateTransaction = Google_Protobuf_Timestamp(req.dateTransaction)
            $0.note = req.note
            guard let transactionType = TransactionType(rawValue: req.type) else {
                throw ErrorModel(humanText: "Неизвестный тип транзакции: \(req.type)")
            }
            $0.type = try transactionType.toProto()
            $0.isExecuted = req.isExecuted
            $0.tagIds = req.tagIDs.map { $0.data }
            $0.datetimeCreate = Google_Protobuf_Timestamp(req.datetimeCreate)
            $0.accountingInCharts = req.accountingInCharts
            $0.accountGroupID = req.accountGroupID.data
        }
        
        let response = try await transactionClient.createTransaction(request)
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
    }
    
    func UpdateTransaction(req: UpdateTransactionReq) async throws {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = Transaction_UpdateTransactionRequest.with {
            $0.accessToken = accessToken
            $0.id = req.id.data
            if let accountFromID = req.accountFromID {
                $0.accountFromID = accountFromID.data
            }
            if let accountToID = req.accountToID {
                $0.accountToID = accountToID.data
            }
            if let amountFrom = req.amountFrom {
                $0.amountFrom = amountFrom.doubleValue
            }
            if let amountTo = req.amountTo {
                $0.amountTo = amountTo.doubleValue
            }
            if let dateTransaction = req.dateTransaction {
                $0.dateTransaction = Google_Protobuf_Timestamp(dateTransaction)
            }
            if let note = req.note {
                $0.note = note
            }
            if let tagIDs = req.tagIDs {
                $0.tagIds = tagIDs.map { $0.data }
            }
            if let accountingInCharts = req.accountingInCharts {
                $0.accountingInCharts = accountingInCharts
            }
        }
        
        let response = try await transactionClient.updateTransaction(request)
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
    }
    
    func DeleteTransaction(req: DeleteTransactionReq) async throws {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = Transaction_DeleteTransactionRequest.with {
            $0.accessToken = accessToken
            $0.id = req.id.data
        }
        
        let response = try await transactionClient.deleteTransaction(request)
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
    }
}
