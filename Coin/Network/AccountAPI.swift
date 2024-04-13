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
                
        return try await request(
            url: apiBasePath + accountBasePath,
            method: .get,
            headers: getBaseHeaders(),
            query: ["dateFrom": dateFrom, "dateTo": dateTo],
            resModel: [GetAccountsRes].self
        )
    }
    
    func GetAccountGroups() async throws -> [GetAccountGroupsRes] {
        return try await request(
            url: apiBasePath + accountBasePath + "/accountGroups",
            method: .get,
            headers: getBaseHeaders(),
            resModel: [GetAccountGroupsRes].self
        )
    }
    
    func CreateAccount(req: CreateAccountReq) async throws -> CreateAccountRes {
        return try await request(
            url: apiBasePath + accountBasePath,
            method: .post,
            headers: getBaseHeaders(),
            reqModel: req,
            resModel: CreateAccountRes.self
        )
    }
    
    func UpdateAccount(req: UpdateAccountReq) async throws -> UpdateAccountRes {
        return try await request(
            url: apiBasePath + accountBasePath,
            method: .patch,
            headers: getBaseHeaders(),
            reqModel: req,
            resModel: UpdateAccountRes.self
        )
    }
    
    func DeleteAccount(req: DeleteAccountReq) async throws {
        return try await request(
            url: apiBasePath + accountBasePath,
            method: .delete,
            headers: getBaseHeaders(),
            query: ["id": String(req.id)]
        )
    }
}
