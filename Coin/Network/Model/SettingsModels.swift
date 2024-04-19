//
//  SettingsModels.swift
//  Coin
//
//  Created by Илья on 19.04.2024.
//

import Foundation

struct GetCurrenciesRes: Decodable {
    var isoCode: String
    var rate: Decimal
    var name: String
    var symbol: String
}

struct GetVersionRes: Decodable {
    var version: String
    var build: String
}
