//
//  UserModel.swift
//  Coin
//
//  Created by Илья on 16.11.2023.
//

import Foundation

struct GetUserRes: Decodable {
    var id: UInt32
    var name: String
    var email: String
    var defaultCurrency: String
}
