//
//  UserAPI.swift
//  Coin
//
//  Created by Илья on 22.10.2023.
//

import Foundation

class UserAPI: API {
    
    let userBasePath = "/user"
    
    func GetUser() async throws -> GetUserRes {
        return try await request(
            url: apiBasePath + userBasePath + "/",
            method: .get,
            headers: getBaseHeaders(),
            resModel: GetUserRes.self)
    }
}
