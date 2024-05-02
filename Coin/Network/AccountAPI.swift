//
//  AccountAPI.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "AccountAPI")

let accountBasePath = "/account"

class AccountAPI: API {
    
    func GetAccounts(req: GetAccountsReq) async throws -> [GetAccountsRes] {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateFrom = dateFormatter.string(from: req.dateFrom!)
        let dateTo = dateFormatter.string(from: req.dateTo!)
                
        let data = try await request(
            url: apiBasePath + accountBasePath,
            method: .get,
            headers: getBaseHeaders(),
            query: ["dateFrom": dateFrom, "dateTo": dateTo]
        )
        
        return try decode(data, model: [GetAccountsRes].self)
    }
    
    func GetAccountGroups() async throws -> [GetAccountGroupsRes] {
        let data = try await request(
            url: apiBasePath + accountBasePath + "/accountGroups",
            method: .get,
            headers: getBaseHeaders()
        )
        
        return try decode(data, model: [GetAccountGroupsRes].self)
    }
    
    func CreateAccount(req: CreateAccountReq) async throws -> CreateAccountRes {
        let data = try await request(
            url: apiBasePath + accountBasePath,
            method: .post,
            headers: getBaseHeaders(),
            body: req
        )
        
        return try decode(data, model: CreateAccountRes.self)
    }
    
    func UpdateAccount(req: UpdateAccountReq) async throws -> UpdateAccountRes {
        let data = try await request(
            url: apiBasePath + accountBasePath,
            method: .patch,
            headers: getBaseHeaders(),
            body: req
        )
        
        return try decode(data, model: UpdateAccountRes.self)
    }
    
    func DeleteAccount(req: DeleteAccountReq) async throws {
        _ = try await request(
            url: apiBasePath + accountBasePath,
            method: .delete,
            headers: getBaseHeaders(),
            query: ["id": String(req.id)]
        )
    }
}
