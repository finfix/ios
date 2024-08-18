//
//  SettingsAPI.swift
//  Coin
//
//  Created by Илья on 19.04.2024.
//

import Foundation

private let settingsBasePath = "/settings"

extension APIManager {
    
    func GetCurrencies() async throws -> [GetCurrenciesRes] {
        let data = try await networkManager.request(
            url: apiBasePath + settingsBasePath + "/currencies",
            method: .get
        )
        
        return try networkManager.decode(data, model: [GetCurrenciesRes].self)
    }
    
    func GetVersion(_ name: String) async throws -> GetVersionRes {
        let data = try await networkManager.request(
            url: apiBasePath + settingsBasePath + "/version/\(name)",
            method: .get,
            withAuthorization: false
        )
        
        return try networkManager.decode(data, model: GetVersionRes.self)
    }
    
    func GetIcons() async throws -> [GetIconsRes] {
        let data = try await networkManager.request(
            url: apiBasePath + settingsBasePath + "/icons",
            method: .get
        )
        
        return try networkManager.decode(data, model: [GetIconsRes].self)
    }
    
    func GetIcon(url: String) async throws -> Data {
        return try await networkManager.request(
            url: url,
            method: .get,
            withAuthorization: false
        )
    }
}
