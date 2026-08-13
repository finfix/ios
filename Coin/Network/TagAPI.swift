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

extension Tag_CreateTagRequest {
    init(
        id: UUID,
        name: String,
        accountGroupID: UUID,
        datetimeCreate: Date
    ) {
        self.init()
        self.id = id.data
        self.name = name
        self.accountGroupID = accountGroupID.data
        self.datetimeCreate = Google_Protobuf_Timestamp(datetimeCreate)
    }
}

extension Tag_UpdateTagRequest {
    init(
        id: UUID,
        name: String?
    ) {
        self.init()
        self.id = id.data
        if let name {
            self.name = name
        }
    }
}

extension Tag_DeleteTagRequest {
    init(id: UUID) {
        self.init()
        self.id = id.data
    }
}

extension APIManager {

    func GetTags() async throws -> [GetTagsRes] {

        let response = try await grpcCall("GetTags", request: Tag_GetTagsRequest()) {
            try await tagClient.getTags($0)
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

        let response = try await grpcCall("GetTagsToTransactions", request: Tag_GetTagsToTransactionsRequest()) {
            try await tagClient.getTagsToTransactions($0)
        }

        return try response.tagsToTransactions.map { tagToTransaction in
            GetTagsToTransactionsRes(
                tagID: try tagToTransaction.tagID.toUUID(),
                transactionID: try tagToTransaction.transactionID.toUUID()
            )
        }
    }

    func CreateTag(req: CreateTagReq) async throws {

        let request = Tag_CreateTagRequest(
            id: req.id,
            name: req.name,
            accountGroupID: req.accountGroupID,
            datetimeCreate: req.datetimeCreate
        )

        _ = try await grpcCall("CreateTag", request: request) {
            try await tagClient.createTag($0)
        }
    }

    func UpdateTag(req: UpdateTagReq) async throws {

        let request = Tag_UpdateTagRequest(id: req.id, name: req.name)

        _ = try await grpcCall("UpdateTag", request: request) {
            try await tagClient.updateTag($0)
        }
    }

    func DeleteTag(req: DeleteTagReq) async throws {

        let request = Tag_DeleteTagRequest(id: req.id)

        _ = try await grpcCall("DeleteTag", request: request) {
            try await tagClient.deleteTag($0)
        }
    }

    func LinkTagToTransaction(req: LinkTagToTransactionReq) async throws {

//        let request = Tag_LinkTagToTransactionRequest.with {
//            $0.tagID = req.tagID.data
//            $0.transactionID = req.transactionID.data
//        }
//
//        _ = try await grpcCall("LinkTagToTransaction", request: request) {
//            try await tagClient.linkTagToTransaction($0)
//        }
    }
}
