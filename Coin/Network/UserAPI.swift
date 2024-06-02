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
        let data = try await request(
            url: apiBasePath + userBasePath,
            method: .get,
            headers: getBaseHeaders()
        )
        
        return try decode(data, model: GetUserRes.self)
    }
    
    func UpdateUser(req: UpdateUserReq) async throws {
        let data = try await request(
            url: apiBasePath + userBasePath,
            method: .patch,
            headers: getBaseHeaders(),
            body: req
        )
    }
}
