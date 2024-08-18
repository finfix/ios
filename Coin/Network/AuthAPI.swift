//
//  AuthAPI.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import SwiftUI

private let authBasePath = "/auth"

extension APIManager {
    
    func Auth(req: AuthReq) async throws -> AuthRes {
        let data = try await networkManager.request(
            url: apiBasePath + authBasePath + "/signIn",
            method: .post,
            headers: ["DeviceID": UIDevice.current.identifierForVendor!.uuidString],
            withAuthorization: false,
            body: req
        )
        
        return try networkManager.decode(data, model: AuthRes.self)
    }
    
    func Register(req: RegisterReq) async throws -> AuthRes {
        let data = try await networkManager.request(
            url: apiBasePath + authBasePath + "/signUp",
            method: .post,
            headers: ["DeviceID": UIDevice.current.identifierForVendor!.uuidString],
            withAuthorization: false,
            body: req
        )
        
        return try networkManager.decode(data, model: AuthRes.self)
    }
}
