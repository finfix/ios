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

private let accountBasePath = "/account"

extension APIManager {
    
    
    func GetAccounts(req: GetAccountsReq) async throws -> [GetAccountsRes] {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateFrom = dateFormatter.string(from: req.dateFrom!)
        let dateTo = dateFormatter.string(from: req.dateTo!)
                
        let data = try await networkManager.request(
            url: apiBasePath + accountBasePath,
            method: .get,
            query: ["dateFrom": dateFrom, "dateTo": dateTo]
        )
        
        if data.count == 5 {
            return []
        }
        
        return try networkManager.decode(data, model: [GetAccountsRes].self)
    }
    
    func CreateAccount(req: CreateAccountReq) async throws -> CreateAccountRes {
        let data = try await networkManager.request(
            url: apiBasePath + accountBasePath,
            method: .post,
            body: req
        )
        
        return try networkManager.decode(data, model: CreateAccountRes.self)
    }
    
    func UpdateAccount(req: UpdateAccountReq) async throws -> UpdateAccountRes {
        let data = try await networkManager.request(
            url: apiBasePath + accountBasePath,
            method: .patch,
            body: req
        )
        
        return try networkManager.decode(data, model: UpdateAccountRes.self)
    }
    
    func DeleteAccount(req: DeleteAccountReq) async throws {
        _ = try await networkManager.request(
            url: apiBasePath + accountBasePath,
            method: .delete,
            query: ["id": String(req.id)]
        )
    }
}
