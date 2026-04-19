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

extension APIManager {
    
    func GetUser() async throws -> GetUserRes {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = User_GetUserRequest.with {
            $0.accessToken = accessToken
        }
        
        let response = try await grpcCall("GetUser", request: request) {
            try await userClient.getUser($0)
        }
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
        
        return GetUserRes(
            id: try response.user.id.toUUID(),
            name: response.user.name,
            email: response.user.email,
            defaultCurrency: response.user.defaultCurrency
        )
    }
    
    func UpdateUser(req: UpdateUserReq) async throws {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = User_UpdateUserRequest.with {
            $0.accessToken = accessToken
            if let name = req.name {
                $0.name = name
            }
            if let email = req.email {
                $0.email = email
            }
            if let password = req.password {
                $0.password = password
            }
            if let oldPassword = req.oldPassword {
                $0.oldPassword = oldPassword
            }
            if let defaultCurrency = req.defaultCurrency {
                $0.defaultCurrency = defaultCurrency
            }
            if let notificationToken = req.notificationToken {
                $0.notificationToken = notificationToken
            }
        }
        
        let response = try await grpcCall("UpdateUser", request: request) {
            try await userClient.updateUser($0)
        }
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
    }
}
