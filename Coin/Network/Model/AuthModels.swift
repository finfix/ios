//
//  AuthModels.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import SwiftUI
import DeviceKit

struct AuthReq: Encodable {
    var email: String
    var password: String
    let application: ApplicationInformation
    let device: DeviceInformation
}

struct ApplicationInformation: Encodable {
    let bundleID: String
    let version: String
    let build: String
}

struct DeviceInformation: Encodable {
    let nameOS: String
    let versionOS: String
    let deviceName: String
    let modelName: String
}

struct RegisterReq: Encodable {
    var email: String
    var password: String
    var name: String
    let application: ApplicationInformation
    let device: DeviceInformation
}

func getDeviceInformation() -> DeviceInformation {
    return DeviceInformation(
        nameOS: UIDevice.current.systemName,
        versionOS: UIDevice.current.systemVersion,
        deviceName: UIDevice.current.model,
        modelName: Device.current.description
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

struct AuthRes: Decodable {
    var id: Int
    var token: Token
}

struct Token: Decodable {
    var accessToken: String
    var refreshToken: String
}

struct RefreshTokensRes: Decodable {
    var accessToken: String
    var refreshToken: String
}

struct RefreshTokensReq: Encodable {
    var token: String
    let application: ApplicationInformation
    let device: DeviceInformation
}
