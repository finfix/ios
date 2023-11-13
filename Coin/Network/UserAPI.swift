//
//  UserAPI.swift
//  Coin
//
//  Created by Илья on 22.10.2023.
//

import Foundation

class UserAPI: API {
    
    let userBasePath = "/user"
    
    func GetCurrencies() async throws -> [Currency] {
        return try await request(
            url: basePath + userBasePath + "/currencies",
            method: .get,
            headers: getBaseHeaders(),
            resModel: [Currency].self)
    }
    
    func GetUser() async throws -> User {
        return try await request(
            url: basePath + userBasePath + "/",
            method: .get,
            headers: getBaseHeaders(),
            resModel: User.self)
    }
}
