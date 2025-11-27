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

extension APIManager {
    
    func GetAccountGroups() async throws -> [GetAccountGroupsRes] {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = AccountGroup_GetAccountGroupsRequest.with {
            $0.accessToken = accessToken
        }
        
        let response = try await accountGroupClient.getAccountGroups(request)
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
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
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = AccountGroup_CreateAccountGroupRequest.with {
            $0.accessToken = accessToken
            $0.name = req.name
            $0.currency = req.currency
            $0.datetimeCreate = Google_Protobuf_Timestamp(req.datetimeCreate)
        }
        
        let response = try await accountGroupClient.createAccountGroup(request)
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
    }
    
    func UpdateAccountGroup(req: UpdateAccountGroupReq) async throws {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = AccountGroup_UpdateAccountGroupRequest.with {
            $0.accessToken = accessToken
            $0.id = req.id.data
            if let name = req.name {
                $0.name = name
            }
            if let currency = req.currency {
                $0.currency = currency
            }
        }
        
        let response = try await accountGroupClient.updateAccountGroup(request)
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
    }
    
    func DeleteAccountGroup(req: DeleteAccountGroupReq) async throws {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = AccountGroup_DeleteAccountGroupRequest.with {
            $0.accessToken = accessToken
            $0.id = req.id.data
        }
        
        let response = try await accountGroupClient.deleteAccountGroup(request)
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
    }
}
