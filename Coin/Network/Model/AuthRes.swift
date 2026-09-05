//
//  AuthModels.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import SwiftUI
import DeviceKit

struct AuthRes: Decodable {
    var id: UUID
    var token: Token
}
