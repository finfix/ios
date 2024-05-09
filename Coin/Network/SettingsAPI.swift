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
        let data = try await request(
            url: apiBasePath + settingsBasePath + "/currencies",
            method: .get,
            headers: getBaseHeaders()
        )
        
        return try decode(data, model: [GetCurrenciesRes].self)
    }
    
    func GetVersion() async throws -> GetVersionRes {
        let data = try await request(
            url: apiBasePath + settingsBasePath + "/version",
            method: .get
        )
        
        return try decode(data, model: GetVersionRes.self)
    }
    
    func GetIcons() async throws -> [GetIconsRes] {
        let data = try await request(
            url: apiBasePath + settingsBasePath + "/icons",
            method: .get,
            headers: getBaseHeaders()
        )
        
        return try decode(data, model: [GetIconsRes].self)
    }
    
    func GetIcon(url: String) async throws -> Data {
        return try await request(
            url: url,
            method: .get
        )
    }
}
