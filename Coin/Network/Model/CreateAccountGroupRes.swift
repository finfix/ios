//
//  AccountGroupModels.swift
//  Coin
//
//  Created by Илья on 23.05.2024.
//

import Foundation

struct CreateAccountGroupRes: Decodable {
    let id: UUID
    let serialNumber: UInt32
}
