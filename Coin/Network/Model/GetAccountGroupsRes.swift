//
//  AccountGroupModels.swift
//  Coin
//
//  Created by Илья on 23.05.2024.
//

import Foundation

struct GetAccountGroupsRes: Decodable {
    let id: UUID
    let name: String
    let currency: String
    let serialNumber: UInt32
    let datetimeCreate: Date
}
