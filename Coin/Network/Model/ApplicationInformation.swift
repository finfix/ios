//
//  AuthModels.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import SwiftUI
import DeviceKit

struct ApplicationInformation: Encodable {
    let bundleID: String
    let version: String
    let build: String
}
