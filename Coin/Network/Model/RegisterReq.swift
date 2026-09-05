//
//  AuthModels.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import SwiftUI
import DeviceKit

struct RegisterReq: Encodable {
    var email: String
    var password: String
    var name: String
    let application: ApplicationInformation
    let device: DeviceInformation
}
