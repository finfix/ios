//
//  AuthModels.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import SwiftUI
import DeviceKit

struct DeviceInformation: Encodable {
    let nameOS: String
    let versionOS: String
    let deviceName: String
    let modelName: String
    let deviceID: String
}
