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
    
    #if os(iOS)
    let deviceID = UIDevice.current.identifierForVendor!.uuidString
    #else
    let deviceID = Host.current().name!
    #endif
    
    func Auth(req: AuthReq) async throws -> AuthRes {
        return try await request(
            url: basePath + authBasePath + "/signIn",
            method: .post,
            headers: ["DeviceID": deviceID],
            reqModel: req,
            resModel: AuthRes.self
        )
    }
    
    func Register(req: RegisterReq) async throws -> AuthRes {
        return try await request(
            url: basePath + authBasePath + "/signUp",
            method: .post,
            headers: ["DeviceID": deviceID],
            reqModel: req,
            resModel: AuthRes.self
        )
    }
    
    func RefreshToken(req: RefreshTokensReq) async throws -> RefreshTokensRes {
        return try await request(
            url: basePath + authBasePath + "/refreshTokens",
            method: .get,
            headers: ["DeviceID": deviceID],
            query: ["token": req.token],
            resModel: RefreshTokensRes.self
        )
    }
}
