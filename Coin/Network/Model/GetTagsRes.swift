//
//  TagModels.swift
//  Coin
//
//  Created by Илья on 20.04.2024.
//

import Foundation

struct GetTagsRes: Decodable {
    let id: UUID
    let name: String
    let accountGroupID: UUID
    let datetimeCreate: Date
}
