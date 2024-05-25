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

let accountGroupBasePath = "/accountGroup"

class AccountGroupAPI: API {
    
    func GetAccountGroups() async throws -> [GetAccountGroupsRes] {
        let data = try await request(
            url: apiBasePath + accountGroupBasePath,
            method: .get,
            headers: getBaseHeaders()
        )
        
        return try decode(data, model: [GetAccountGroupsRes].self)
    }
    
    func CreateAccountGroup(req: CreateAccountGroupReq) async throws -> CreateAccountGroupRes {
        let data = try await request(
            url: apiBasePath + accountGroupBasePath,
            method: .post,
            headers: getBaseHeaders(),
            body: req
        )
        
        return try decode(data, model: CreateAccountGroupRes.self)
    }
    
    func UpdateAccountGroup(req: UpdateAccountGroupReq) async throws {
        _ = try await request(
            url: apiBasePath + accountGroupBasePath,
            method: .patch,
            headers: getBaseHeaders(),
            body: req
        )
    }
    
    func DeleteAccountGroup(req: DeleteAccountGroupReq) async throws {
        _ = try await request(
            url: apiBasePath + accountGroupBasePath,
            method: .delete,
            headers: getBaseHeaders(),
            query: ["id": String(req.id)]
        )
    }
}
