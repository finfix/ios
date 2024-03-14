//
//  UserModel.swift
//  Coin
//
//  Created by Илья on 16.11.2023.
//

import Foundation

struct GetCurrenciesRes: Decodable {
    var id: String
    var rate: Decimal
    var name: String
    var symbol: String
}

struct GetUserRes: Decodable {
    var id: UInt32
    var name: String
    var email: String
//    var timeCreate: Date
    var defaultCurrency: String
}
