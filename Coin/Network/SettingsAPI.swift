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

extension Settings_GetVersionRequest {
    init(applicationType: ApplicationType_ApplicationType) {
        self.init()
        self.applicationType = applicationType
    }
}

extension APIManager {

    func GetCurrencies() async throws -> [GetCurrenciesRes] {

        let response = try await grpcCall("GetCurrencies", request: Settings_GetCurrenciesRequest()) {
            try await settingsClient.getCurrencies($0)
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

        let request = Settings_GetVersionRequest(applicationType: .ios)

        let response = try await grpcCall("GetVersion", request: request) {
            try await settingsClient.getVersion($0)
        }

        return GetVersionRes(
            version: response.version.version,
            build: response.version.build
        )
    }

    func GetIcons() async throws -> [GetIconsRes] {

        let response = try await grpcCall("GetIcons", request: Settings_GetIconsRequest()) {
            try await settingsClient.getIcons($0)
        }

        return try response.icons.map { icon in
            GetIconsRes(
                id: try icon.id.toUUID(),
                name: icon.name,
                image: icon.image
            )
        }
    }
}
