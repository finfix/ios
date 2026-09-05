//
//  AuthModels.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import SwiftUI
import DeviceKit

struct Token: Decodable {
    var accessToken: String
    var refreshToken: String
}
