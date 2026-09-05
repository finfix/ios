//
//  AuthModels.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import SwiftUI
import DeviceKit





func getDeviceInformation() -> DeviceInformation {
    return DeviceInformation(
        nameOS: UIDevice.current.systemName,
        versionOS: UIDevice.current.systemVersion,
        deviceName: UIDevice.current.model,
        modelName: Device.current.description,
        deviceID: UIDevice.current.identifierForVendor!.uuidString
    )
}

func getApplicationInformation() throws -> ApplicationInformation {
    guard let bundleID = Bundle.main.bundleIdentifier else {
        throw ErrorModel(humanText: "Не смогли получить Bundle Identifier приложения")
    }
    guard let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
        throw ErrorModel(humanText: "Не смогли получить версию приложения")
    }
    guard let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
        throw ErrorModel(humanText: "Не смогли получить билд приложения")
    }
    return ApplicationInformation(
        bundleID: bundleID,
        version: appVersion,
        build: buildNumber
    )
}




