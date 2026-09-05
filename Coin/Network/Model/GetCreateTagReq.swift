//
//  TagModels.swift
//  Coin
//
//  Created by Илья on 20.04.2024.
//

import Foundation

struct GetCreateTagReq: Codable {
    let accountGroupID: UUID
    let name: UInt32
}
