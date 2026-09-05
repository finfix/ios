//
//  UserModel.swift
//  Coin
//
//  Created by Илья on 16.11.2023.
//

import Foundation

struct GetUserRes: Decodable {
    var id: UUID
    var name: String
    var email: String
    var defaultCurrency: String
}
