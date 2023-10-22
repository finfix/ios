//
//  Currencies.swift
//  Coin
//
//  Created by Илья on 21.10.2023.
//

import Foundation

struct Currency: Decodable {
    var isoCode: String = ""
    var name: String = ""
    var rate: Double = 1
    var symbol: String = ""
}
