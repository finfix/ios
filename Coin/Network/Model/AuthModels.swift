//
//  AuthModels.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation

struct AuthRequest: Encodable {
    var email: String
    var password: String
}

struct AuthResponse: Decodable {
    var id: Int
    var token: Token
}

struct Token: Decodable {
    var accessToken: String
    var refreshToken: String
}

struct RefreshTokensResponse: Decodable {
    var accessToken: String
    var refreshToken: String
}

struct RefreshTokensRequest: Encodable {
    var token: String
}
