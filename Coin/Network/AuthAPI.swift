//
//  AuthAPI.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import SwiftUI

class AuthAPI: API {
    
    let authBasePath = "/auth"
    
    func Auth(req: AuthReq) async throws -> AuthRes {
        let data = try await request(
            url: apiBasePath + authBasePath + "/signIn",
            method: .post,
            headers: ["DeviceID": UIDevice.current.identifierForVendor!.uuidString], 
            body: req,
            handleUnauthorized: false
        )
        
        return try decode(data, model: AuthRes.self)
    }
    
    func Register(req: RegisterReq) async throws -> AuthRes {
        let data = try await request(
            url: apiBasePath + authBasePath + "/signUp",
            method: .post,
            headers: ["DeviceID": UIDevice.current.identifierForVendor!.uuidString],
            body: req,
            handleUnauthorized: false
        )
        
        return try decode(data, model: AuthRes.self)
    }
    
    func RefreshToken(req: RefreshTokensReq) async throws -> RefreshTokensRes {
        var headers = try getBaseHeaders()
        headers["DeviceID"] = await UIDevice.current.identifierForVendor!.uuidString
        let data = try await request(
            url: apiBasePath + authBasePath + "/refreshTokens",
            method: .post,
            headers: headers,
            body: req,
            handleUnauthorized: false
        )
        
        return try decode(data, model: RefreshTokensRes.self)
    }
}
