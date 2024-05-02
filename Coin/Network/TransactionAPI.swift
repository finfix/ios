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
        
        let data = try await request(
            url: apiBasePath + transactionBasePath,
            method: .get,
            headers: getBaseHeaders()
        )
        
        return try decode(data, model: [GetTransactionsRes].self)
        
    }
    
    func CreateTransaction(req: CreateTransactionReq) async throws -> UInt32 {
        
        let data = try await request(
            url: apiBasePath + transactionBasePath,
            method: .post,
            headers: getBaseHeaders(),
            body: req
        )
        
        return try decode(data, model: CreateTransactionRes.self).id
    }
    
    func UpdateTransaction(req: UpdateTransactionReq) async throws {
        _ = try await request(
            url: apiBasePath + transactionBasePath,
            method: .patch,
            headers: getBaseHeaders(),
            body: req
        )
    }
    
    func DeleteTransaction(req: DeleteTransactionReq) async throws {
        _ = try await request(
            url: apiBasePath + transactionBasePath,
            method: .delete,
            headers: getBaseHeaders(),
            query: ["id": String(req.id)]
        )
    }
}
