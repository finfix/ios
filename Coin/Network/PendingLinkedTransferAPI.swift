//
//  PendingLinkedTransferAPI.swift
//  Coin
//

import Foundation
import SwiftUI
import ProtoDefinitions
import GRPCCore
import GRPCProtobuf
import GRPCNIOTransportHTTP2
import SwiftProtobuf

extension PendingLinkedTransfer_GetPendingLinkedTransfersRequest {
    init(
        accountGroupIDs: [UUID],
        targetAccountIDs: [UUID]
    ) {
        self.init()
        self.accountGroupIds = accountGroupIDs.map(\.data)
        self.targetAccountIds = targetAccountIDs.map(\.data)
    }
}

extension PendingLinkedTransfer_CreatePendingLinkedTransferRequest {
    init(
        id: UUID,
        sourceTransactionID: UUID,
        sourceAccountID: UUID,
        targetAccountID: UUID,
        accountGroupID: UUID
    ) {
        self.init()
        self.id = id.data
        self.sourceTransactionID = sourceTransactionID.data
        self.sourceAccountID = sourceAccountID.data
        self.targetAccountID = targetAccountID.data
        self.accountGroupID = accountGroupID.data
    }
}

extension PendingLinkedTransfer_UpdatePendingLinkedTransferRequest {
    init(
        id: UUID,
        status: PendingLinkedTransferStatus?
    ) throws {
        self.init()
        self.id = id.data
        if let status {
            self.status = try status.toProto()
        }
    }
}

extension PendingLinkedTransfer_DeletePendingLinkedTransferRequest {
    init(id: UUID) {
        self.init()
        self.id = id.data
    }
}

extension APIManager {

    func GetPendingLinkedTransfers(req: GetPendingLinkedTransfersReq) async throws -> [GetPendingLinkedTransfersRes] {

        let request = PendingLinkedTransfer_GetPendingLinkedTransfersRequest(
            accountGroupIDs: req.accountGroupIDs,
            targetAccountIDs: req.targetAccountIDs
        )

        let response = try await grpcCall("GetPendingLinkedTransfers", request: request) {
            try await pendingLinkedTransferClient.getPendingLinkedTransfers($0)
        }

        return try response.pendingLinkedTransfers.map { transfer in
            GetPendingLinkedTransfersRes(
                id: try transfer.id.toUUID(),
                status: try PendingLinkedTransferStatus(from: transfer.status),
                sourceTransactionID: try transfer.sourceTransactionID.toUUID(),
                sourceAccountID: try transfer.sourceAccountID.toUUID(),
                targetAccountID: try transfer.targetAccountID.toUUID(),
                accountGroupID: try transfer.accountGroupID.toUUID()
            )
        }
    }

    func CreatePendingLinkedTransfer(req: CreatePendingLinkedTransferReq) async throws {

        let request = PendingLinkedTransfer_CreatePendingLinkedTransferRequest(
            id: req.id,
            sourceTransactionID: req.sourceTransactionID,
            sourceAccountID: req.sourceAccountID,
            targetAccountID: req.targetAccountID,
            accountGroupID: req.accountGroupID
        )

        _ = try await grpcCall("CreatePendingLinkedTransfer", request: request) {
            try await pendingLinkedTransferClient.createPendingLinkedTransfer($0)
        }
    }

    func UpdatePendingLinkedTransfer(req: UpdatePendingLinkedTransferReq) async throws {

        let request = try PendingLinkedTransfer_UpdatePendingLinkedTransferRequest(
            id: req.id,
            status: req.status
        )

        _ = try await grpcCall("UpdatePendingLinkedTransfer", request: request) {
            try await pendingLinkedTransferClient.updatePendingLinkedTransfer($0)
        }
    }

    func DeletePendingLinkedTransfer(req: DeletePendingLinkedTransferReq) async throws {

        let request = PendingLinkedTransfer_DeletePendingLinkedTransferRequest(id: req.id)

        _ = try await grpcCall("DeletePendingLinkedTransfer", request: request) {
            try await pendingLinkedTransferClient.deletePendingLinkedTransfer($0)
        }
    }
}
