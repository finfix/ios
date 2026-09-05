//
//  AuthModels.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import SwiftUI
import DeviceKit

struct RefreshTokensReq: Encodable {
    var token: String
    let application: ApplicationInformation
    let device: DeviceInformation
}
