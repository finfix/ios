//
//  TransactionAPI.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

private var transactionBasePath = "/transaction"

extension APIManager {
    
    func GetTransactions(req: GetTransactionReq) async throws -> [GetTransactionsRes] {
        
        let data = try await networkManager.request(
            url: apiBasePath + transactionBasePath,
            method: .get
        )
        
        if data.count == 5 {
            return []
        }
        
        return try networkManager.decode(data, model: [GetTransactionsRes].self)
        
    }
    
    func CreateTransaction(req: CreateTransactionReq) async throws -> UInt32 {
        
        let data = try await networkManager.request(
            url: apiBasePath + transactionBasePath,
            method: .post,
            body: req
        )
        
        return try networkManager.decode(data, model: CreateTransactionRes.self).id
    }
    
    func UpdateTransaction(req: UpdateTransactionReq) async throws {
        _ = try await networkManager.request(
            url: apiBasePath + transactionBasePath,
            method: .patch,
            body: req
        )
    }
    
    func DeleteTransaction(req: DeleteTransactionReq) async throws {
        _ = try await networkManager.request(
            url: apiBasePath + transactionBasePath,
            method: .delete,
            query: ["id": String(req.id)]
        )
    }
}
