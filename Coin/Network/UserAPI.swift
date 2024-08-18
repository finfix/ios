//
//  UserAPI.swift
//  Coin
//
//  Created by Илья on 22.10.2023.
//

import Foundation

private let userBasePath = "/user"

extension APIManager {
    
    
    func GetUser() async throws -> GetUserRes {
        let data = try await networkManager.request(
            url: apiBasePath + userBasePath,
            method: .get
        )
        
        return try networkManager.decode(data, model: GetUserRes.self)
    }
    
    func UpdateUser(req: UpdateUserReq) async throws {
        let data = try await networkManager.request(
            url: apiBasePath + userBasePath,
            method: .patch,
            body: req
        )
    }
}
