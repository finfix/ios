//
//  TagAPI.swift
//  Coin
//
//  Created by Илья on 20.04.2024.
//

import Foundation

class TagAPI: API {
    
    let tagBasePath = "/tag"
    
    func GetTags() async throws -> [GetTagsRes] {
        let data = try await request(
            url: apiBasePath + tagBasePath,
            method: .get,
            headers: getBaseHeaders()
        )
        
        return try decode(data, model: [GetTagsRes].self)
    }
    
    func GetTagsToTransaction() async throws -> [GetTagsToTransactionsRes] {
        let data = try await request(
            url: apiBasePath + tagBasePath + "/to_transactions",
            method: .get,
            headers: getBaseHeaders()
        )
        
        return try decode(data, model: [GetTagsToTransactionsRes].self)
    }
    
    func CreateTag(req: CreateTagReq) async throws -> UInt32 {
        let data = try await request(
            url: apiBasePath + tagBasePath,
            method: .post,
            headers: getBaseHeaders(),
            body: req
        )
        
        return try decode(data, model:  CreateTagRes.self).id
    }
    
    func UpdateTag(req: UpdateTagReq) async throws {
        _ = try await request(
            url: apiBasePath + tagBasePath,
            method: .patch,
            headers: getBaseHeaders(),
            body: req)
    }
    
    func DeleteTag(req: DeleteTagReq) async throws {
        _ = try await request(
            url: apiBasePath + tagBasePath,
            method: .delete,
            headers: getBaseHeaders(),
            query: ["id": String(req.id)])
    }
    
    func LinkTagToTransaction(req: LinkTagToTransactionReq) async throws {
        _ = try await request(
            url: apiBasePath + tagBasePath + "link_tag_to_transaction",
            method: .post,
            headers: getBaseHeaders(),
            body: req)
    }
}
