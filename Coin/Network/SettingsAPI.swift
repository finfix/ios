//
//  SettingsAPI.swift
//  Coin
//
//  Created by Илья on 19.04.2024.
//

import Foundation
import SwiftProtobuf
import ProtoDefinitions
import GRPCCore
import GRPCProtobuf
import GRPCNIOTransportHTTP2

extension APIManager {
    
    func GetCurrencies() async throws -> [GetCurrenciesRes] {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = Settings_GetCurrenciesRequest.with {
            $0.accessToken = accessToken
        }
        
        let response = try await grpcCall("GetCurrencies", request: request) {
            try await settingsClient.getCurrencies($0)
        }
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
        
        return response.currencies.map { currency in
            GetCurrenciesRes(
                isoCode: currency.isoCode,
                rate: Decimal(currency.rate),
                name: currency.name,
                symbol: currency.symbol
            )
        }
    }
    
    func GetVersion(_ name: String) async throws -> GetVersionRes {
        
        let request = Settings_GetVersionRequest.with {
            $0.applicationType = .ios
        }
        
        let response = try await grpcCall("GetVersion", request: request) {
            try await settingsClient.getVersion($0)
        }
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
        
        return GetVersionRes(
            version: response.version.version,
            build: response.version.build
        )
    }
    
    func GetIcons() async throws -> [GetIconsRes] {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = Settings_GetIconsRequest.with {
            $0.accessToken = accessToken
        }
        
        let response = try await grpcCall("GetIcons", request: request) {
            try await settingsClient.getIcons($0)
        }
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
        
        return try response.icons.map { icon in
            GetIconsRes(
                id: try icon.id.toUUID(),
                url: icon.url,
                name: icon.name
            )
        }
    }
    
    func GetIcon(url: String) async throws -> Data {
        return try await networkManager.request(
            url: url,
            method: .get,
            withAuthorization: false
        )
    }
}
