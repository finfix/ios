//
//  APIs.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation
import SwiftUI

class TransactionAPI: API {
        
    let transactionBasePath = "/transaction"
    
    func GetTransactions(req: GetTransactionReq) async throws -> [GetTransactionsRes] {
        return try await request(
            url: basePath + transactionBasePath,
            method: .get,
            headers: getBaseHeaders(),
            resModel: [GetTransactionsRes].self)
    }
    
    func CreateTransaction(req: CreateTransactionReq) async throws -> UInt32 {
        let format = DateFormatter()
        format.dateFormat = "YYYY-MM-dd"
        return try await request(
            url: basePath + transactionBasePath,
            method: .post,
            headers: getBaseHeaders(),
            reqModel: req,
            resModel: CreateTransactionRes.self
        ).id
    }
    
    func UpdateTransaction(req: UpdateTransactionReq) async throws {
        return try await request(
            url: basePath + transactionBasePath,
            method: .patch,
            headers: getBaseHeaders(),
            reqModel: req
        )
    }
    
    func DeleteTransaction(req: DeleteTransactionReq) async throws {
        return try await request(
            url: basePath + transactionBasePath,
            method: .delete,
            headers: getBaseHeaders(),
            query: ["id": String(req.id)]
        )
    }
}
