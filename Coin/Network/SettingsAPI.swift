//
//  SettingsAPI.swift
//  Coin
//
//  Created by Илья on 19.04.2024.
//

import Foundation

class SettingsAPI: API {
    
    let settingsBasePath = "/settings"
    
    func GetCurrencies() async throws -> [GetCurrenciesRes] {
        return try await request(
            url: apiBasePath + settingsBasePath + "/currencies",
            method: .get,
            headers: getBaseHeaders(),
            resModel: [GetCurrenciesRes].self)
    }
    
    func GetVersion() async throws -> GetVersionRes {
        return try await request(
            url: apiBasePath + settingsBasePath + "/version",
            method: .get,
            resModel: GetVersionRes.self)
    }
}
