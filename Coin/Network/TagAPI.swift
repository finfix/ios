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
        return try await request(
            url: apiBasePath + tagBasePath,
            method: .get,
            headers: getBaseHeaders(),
            resModel: [GetTagsRes].self)
    }
    
    func GetTagsToTransaction() async throws -> [GetTagsToTransactionsRes] {
        return try await request(
            url: apiBasePath + tagBasePath + "/to_transactions",
            method: .get,
            headers: getBaseHeaders(),
            resModel: [GetTagsToTransactionsRes].self)
    }
    
    func CreateTag(req: CreateTagReq) async throws -> UInt32 {
        return try await request(
            url: apiBasePath + tagBasePath,
            method: .post,
            headers: getBaseHeaders(),
            reqModel: req,
            resModel: CreateTagRes.self)
        .id
    }
    
    func UpdateTag(req: UpdateTagReq) async throws {
        return try await request(
            url: apiBasePath + tagBasePath,
            method: .patch,
            headers: getBaseHeaders(),
            reqModel: req)
    }
    
    func DeleteTag(req: DeleteTagReq) async throws {
        return try await request(
            url: apiBasePath + tagBasePath,
            method: .delete,
            headers: getBaseHeaders(),
            query: ["id": String(req.id)])
    }
    
    func LinkTagToTransaction(req: LinkTagToTransactionReq) async throws {
        return try await request(
            url: apiBasePath + tagBasePath + "link_tag_to_transaction",
            method: .post,
            headers: getBaseHeaders(),
            reqModel: req)
    }
}
