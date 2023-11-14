//
//  AccountAPI.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import SwiftUI

let accountBasePath = "/account"

class AccountAPI: API {
    
    func GetAccounts(req: GetAccountsReq) async throws -> [Account] {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateFrom = dateFormatter.string(from: req.dateFrom!)
        let dateTo = dateFormatter.string(from: req.dateTo!)
                
        return try await request(
            url: basePath + accountBasePath,
            method: .get,
            headers: getBaseHeaders(),
            query: ["dateFrom": dateFrom, "dateTo": dateTo],
            resModel: [Account].self
        )
    }
    
    func GetAccountGroups() async throws -> [AccountGroup] {
        return try await request(
            url: basePath + accountBasePath + "/accountGroups",
            method: .get,
            headers: getBaseHeaders(),
            resModel: [AccountGroup].self
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
        do {
            return try await request(
                url: basePath + accountBasePath,
                method: .patch,
                headers: getBaseHeaders(),
                reqModel: req
            )
        } catch {
            debugLog(error)
            showErrorAlert(error.localizedDescription)
        }
    }
}
