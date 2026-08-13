//
//  AccountGroupAPI.swift
//  Coin
//
//  Created by Илья on 23.05.2024.
//

import Foundation
import SwiftUI
import ProtoDefinitions
import GRPCCore
import GRPCProtobuf
import GRPCNIOTransportHTTP2
import SwiftProtobuf

extension AccountGroup_CreateAccountGroupRequest {
    init(
        id: UUID,
        name: String,
        currency: String,
        datetimeCreate: Date
    ) {
        self.init()
        self.id = id.data
        self.name = name
        self.currency = currency
        self.datetimeCreate = Google_Protobuf_Timestamp(datetimeCreate)
    }
}

extension AccountGroup_UpdateAccountGroupRequest {
    init(
        id: UUID,
        name: String?,
        currency: String?
    ) {
        self.init()
        self.id = id.data
        if let name {
            self.name = name
        }
        if let currency {
            self.currency = currency
        }
    }
}

extension AccountGroup_DeleteAccountGroupRequest {
    init(id: UUID) {
        self.init()
        self.id = id.data
    }
}

extension APIManager {

    func GetAccountGroups() async throws -> [GetAccountGroupsRes] {

        let response = try await grpcCall("GetAccountGroups", request: AccountGroup_GetAccountGroupsRequest()) {
            try await accountGroupClient.getAccountGroups($0)
        }

        return try response.accountGroups.map { accountGroup in
            GetAccountGroupsRes(
                id: try accountGroup.id.toUUID(),
                name: accountGroup.name,
                currency: accountGroup.currency,
                serialNumber: accountGroup.serialNumber,
                datetimeCreate: accountGroup.datetimeCreate.toDate()
            )
        }
    }

    func CreateAccountGroup(req: CreateAccountGroupReq) async throws {

        let request = AccountGroup_CreateAccountGroupRequest(
            id: req.id,
            name: req.name,
            currency: req.currency,
            datetimeCreate: req.datetimeCreate
        )

        _ = try await grpcCall("CreateAccountGroup", request: request) {
            try await accountGroupClient.createAccountGroup($0)
        }
    }

    func UpdateAccountGroup(req: UpdateAccountGroupReq) async throws {

        let request = AccountGroup_UpdateAccountGroupRequest(
            id: req.id,
            name: req.name,
            currency: req.currency
        )

        _ = try await grpcCall("UpdateAccountGroup", request: request) {
            try await accountGroupClient.updateAccountGroup($0)
        }
    }

    func DeleteAccountGroup(req: DeleteAccountGroupReq) async throws {

        let request = AccountGroup_DeleteAccountGroupRequest(id: req.id)

        _ = try await grpcCall("DeleteAccountGroup", request: request) {
            try await accountGroupClient.deleteAccountGroup($0)
        }
    }
}
