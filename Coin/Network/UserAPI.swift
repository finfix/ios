//
//  UserAPI.swift
//  Coin
//
//  Created by Илья on 22.10.2023.
//

import Foundation
import ProtoDefinitions
import GRPCCore
import GRPCProtobuf
import GRPCNIOTransportHTTP2
import SwiftProtobuf

extension User_UpdateUserRequest {
    init(
        name: String?,
        email: String?,
        password: String?,
        oldPassword: String?,
        defaultCurrency: String?,
        notificationToken: String?
    ) {
        self.init()
        if let name {
            self.name = name
        }
        if let email {
            self.email = email
        }
        if let password {
            self.password = password
        }
        if let oldPassword {
            self.oldPassword = oldPassword
        }
        if let defaultCurrency {
            self.defaultCurrency = defaultCurrency
        }
        if let notificationToken {
            self.notificationToken = notificationToken
        }
    }
}

extension APIManager {

    func GetUser() async throws -> GetUserRes {

        let response = try await grpcCall("GetUser", request: User_GetUserRequest()) {
            try await userClient.getUser($0)
        }

        return GetUserRes(
            id: try response.user.id.toUUID(),
            name: response.user.name,
            email: response.user.email,
            defaultCurrency: response.user.defaultCurrency
        )
    }

    func UpdateUser(req: UpdateUserReq) async throws {

        let request = User_UpdateUserRequest(
            name: req.name,
            email: req.email,
            password: req.password,
            oldPassword: req.oldPassword,
            defaultCurrency: req.defaultCurrency,
            notificationToken: req.notificationToken
        )

        _ = try await grpcCall("UpdateUser", request: request) {
            try await userClient.updateUser($0)
        }
    }
}
