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
        return try await request(
            url: serverPath + authBasePath + "/signIn",
            method: .post,
            headers: ["DeviceID": UIDevice.current.identifierForVendor!.uuidString], 
            reqModel: req,
            resModel: AuthRes.self
        )
    }
    
    func Register(req: RegisterReq) async throws -> AuthRes {
        return try await request(
            url: serverPath + authBasePath + "/signUp",
            method: .post,
            headers: ["DeviceID": UIDevice.current.identifierForVendor!.uuidString],
            reqModel: req,
            resModel: AuthRes.self
        )
    }
    
    func RefreshToken(req: RefreshTokensReq) async throws -> RefreshTokensRes {
        return try await request(
            url: serverPath + authBasePath + "/refreshTokens",
            method: .get,
            headers: ["DeviceID": UIDevice.current.identifierForVendor!.uuidString],
            query: ["token": req.token],
            resModel: RefreshTokensRes.self
        )
    }
}
