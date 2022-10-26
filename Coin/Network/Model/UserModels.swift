//
//  UserModels.swift
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
    var tokens: Tokens
}

struct Tokens: Decodable {
        var accessToken: String
        var refreshToken: String
    }
