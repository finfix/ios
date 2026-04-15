//
//  TagAPI.swift
//  Coin
//
//  Created by Илья on 20.04.2024.
//

import Foundation
import ProtoDefinitions
import GRPCCore
import GRPCProtobuf
import GRPCNIOTransportHTTP2
import SwiftProtobuf

extension APIManager {
    
    func GetTags() async throws -> [GetTagsRes] {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = Tag_GetTagsRequest.with {
            $0.accessToken = accessToken
        }
        
        let response = try await grpcCall("GetTags", request: request) {
            try await tagClient.getTags($0)
        }
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
        
        return try response.tags.map { tag in
            GetTagsRes(
                id: try tag.id.toUUID(),
                name: tag.name,
                accountGroupID: try tag.accountGroupID.toUUID(),
                datetimeCreate: tag.datetimeCreate.toDate()
            )
        }
    }
    
    func GetTagsToTransaction() async throws -> [GetTagsToTransactionsRes] {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = Tag_GetTagsToTransactionsRequest.with {
            $0.accessToken = accessToken
        }
        
        let response = try await grpcCall("GetTagsToTransactions", request: request) {
            try await tagClient.getTagsToTransactions($0)
        }
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
        
        return try response.tagsToTransactions.map { tagToTransaction in
            GetTagsToTransactionsRes(
                tagID: try tagToTransaction.tagID.toUUID(),
                transactionID: try tagToTransaction.transactionID.toUUID()
            )
        }
    }
    
    func CreateTag(req: CreateTagReq) async throws {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = Tag_CreateTagRequest.with {
            $0.accessToken = accessToken
            $0.name = req.name
            $0.accountGroupID = req.accountGroupID.data
            $0.datetimeCreate = Google_Protobuf_Timestamp(req.datetimeCreate)
        }
        
        let response = try await grpcCall("CreateTag", request: request) {
            try await tagClient.createTag($0)
        }
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
    }
    
    func UpdateTag(req: UpdateTagReq) async throws {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = Tag_UpdateTagRequest.with {
            $0.accessToken = accessToken
            $0.id = req.id.data
            if let name = req.name {
                $0.name = name
            }
        }
        
        let response = try await grpcCall("UpdateTag", request: request) {
            try await tagClient.updateTag($0)
        }
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
    }
    
    func DeleteTag(req: DeleteTagReq) async throws {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = Tag_DeleteTagRequest.with {
            $0.accessToken = accessToken
            $0.id = req.id.data
        }
        
        let response = try await grpcCall("DeleteTag", request: request) {
            try await tagClient.deleteTag($0)
        }
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
    }
    
    func LinkTagToTransaction(req: LinkTagToTransactionReq) async throws {
        
//        let accessToken = try await self.networkManager.authManager.getAccessToken()
//        
//        let request = Tag_LinkTagToTransactionRequest.with {
//            $0.accessToken = accessToken
//            $0.tagID = req.tagID.data
//            $0.transactionID = req.transactionID.data
//        }
//        
//        let response = try await grpcCall("LinkTagToTransaction", request: request) {
//            try await tagClient.linkTagToTransaction($0)
//        }
//        
//        guard !response.hasError else {
//            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
//        }
    }
}
