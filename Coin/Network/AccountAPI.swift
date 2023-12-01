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
            url: basePath + accountBasePath,
            method: .get,
            headers: getBaseHeaders(),
            query: ["dateFrom": dateFrom, "dateTo": dateTo],
            resModel: [GetAccountsRes].self
        )
    }
    
    func GetAccountGroups() async throws -> [GetAccountGroupsRes] {
        return try await request(
            url: basePath + accountBasePath + "/accountGroups",
            method: .get,
            headers: getBaseHeaders(),
            resModel: [GetAccountGroupsRes].self
        )
    }
    
    func CreateAccount(req: CreateAccountReq) async throws -> UInt32 {
        return try await request(
            url: basePath + accountBasePath,
            method: .post,
            headers: getBaseHeaders(),
            reqModel: req,
            resModel: CreateAccountRes.self
        ).id
    }
    
    func UpdateAccount(req: UpdateAccountReq) async throws {
        return try await request(
            url: basePath + accountBasePath,
            method: .patch,
            headers: getBaseHeaders(),
            reqModel: req
        )
    }
}
