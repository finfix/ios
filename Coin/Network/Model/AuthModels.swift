//
//  AuthModels.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation

struct AuthReq: Encodable {
    var email: String
    var password: String
    let os: String = "iOS"
    let bundleID: String
}

struct RegisterReq: Encodable {
    var email: String
    var password: String
    var name: String
    let os: String = "iOS"
    let bundleID: String
}

struct AuthRes: Decodable {
    var id: Int
    var token: Token
}

struct Token: Decodable {
    var accessToken: String
    var refreshToken: String
}

struct RefreshTokensRes: Decodable {
    var accessToken: String
    var refreshToken: String
}

struct RefreshTokensReq: Encodable {
    var token: String
}
