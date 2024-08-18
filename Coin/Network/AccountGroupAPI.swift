//
//  AccountGroupAPI.swift
//  Coin
//
//  Created by Илья on 23.05.2024.
//

import Foundation
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "AccountGroupAPI")

private let accountGroupBasePath = "/accountGroup"

extension APIManager {
    
    func GetAccountGroups() async throws -> [GetAccountGroupsRes] {
        let data = try await networkManager.request(
            url: apiBasePath + accountGroupBasePath,
            method: .get
        )
        
        return try networkManager.decode(data, model: [GetAccountGroupsRes].self)
    }
    
    func CreateAccountGroup(req: CreateAccountGroupReq) async throws -> CreateAccountGroupRes {
        let data = try await networkManager.request(
            url: apiBasePath + accountGroupBasePath,
            method: .post,
            body: req
        )
        
        return try networkManager.decode(data, model: CreateAccountGroupRes.self)
    }
    
    func UpdateAccountGroup(req: UpdateAccountGroupReq) async throws {
        _ = try await networkManager.request(
            url: apiBasePath + accountGroupBasePath,
            method: .patch,
            body: req
        )
    }
    
    func DeleteAccountGroup(req: DeleteAccountGroupReq) async throws {
        _ = try await networkManager.request(
            url: apiBasePath + accountGroupBasePath,
            method: .delete,
            query: ["id": String(req.id)]
        )
    }
}
