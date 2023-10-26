//
//  AccountGroup.swift
//  Coin
//
//  Created by Илья on 19.10.2023.
//

import Foundation

struct AccountGroup: Decodable, Identifiable, Hashable {
    var id: UInt32
    var name: String
    var currency: String
}
