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

struct Changes: Decodable {
    
    var created: Changes?
    var updated: Changes?
    var deleted: Deleted?
    
    struct Changes: Decodable {
        var transactions: [Transaction]?
        var accounts: [Account]?
    }
    
    struct Deleted: Decodable {
        var transactionsID: [Int]?
        var accoutnsID: [Int]?
    }
}
