//
//  UserAPI.swift
//  Coin
//
//  Created by Илья on 22.10.2023.
//

import Foundation

class UserAPI: API {
    
    let userBasePath = "/user"
    
    func GetCurrencies() async throws -> [GetCurrenciesRes] {
        return try await request(
            url: serverPath + userBasePath + "/currencies",
            method: .get,
            headers: getBaseHeaders(),
            resModel: [GetCurrenciesRes].self)
    }
    
    func GetUser() async throws -> GetUserRes {
        return try await request(
            url: serverPath + userBasePath + "/",
            method: .get,
            headers: getBaseHeaders(),
            resModel: GetUserRes.self)
    }
}
