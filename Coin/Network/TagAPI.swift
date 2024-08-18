//
//  TagAPI.swift
//  Coin
//
//  Created by Илья on 20.04.2024.
//

import Foundation

private let tagBasePath = "/tag"

extension APIManager {
    
    func GetTags() async throws -> [GetTagsRes] {
        let data = try await networkManager.request(
            url: apiBasePath + tagBasePath,
            method: .get
        )
        
        if data.count == 5 {
            return []
        }
        
        return try networkManager.decode(data, model: [GetTagsRes].self)
    }
    
    func GetTagsToTransaction() async throws -> [GetTagsToTransactionsRes] {
        let data = try await networkManager.request(
            url: apiBasePath + tagBasePath + "/to_transactions",
            method: .get
        )
                
        if data.count == 5 {
            return []
        }
        
        return try networkManager.decode(data, model: [GetTagsToTransactionsRes].self)
    }
    
    func CreateTag(req: CreateTagReq) async throws -> UInt32 {
        let data = try await networkManager.request(
            url: apiBasePath + tagBasePath,
            method: .post,
            body: req
        )
        
        return try networkManager.decode(data, model:  CreateTagRes.self).id
    }
    
    func UpdateTag(req: UpdateTagReq) async throws {
        _ = try await networkManager.request(
            url: apiBasePath + tagBasePath,
            method: .patch,
            body: req)
    }
    
    func DeleteTag(req: DeleteTagReq) async throws {
        _ = try await networkManager.request(
            url: apiBasePath + tagBasePath,
            method: .delete,
            query: ["id": String(req.id)])
    }
    
    func LinkTagToTransaction(req: LinkTagToTransactionReq) async throws {
        _ = try await networkManager.request(
            url: apiBasePath + tagBasePath + "link_tag_to_transaction",
            method: .post,
            body: req)
    }
}
