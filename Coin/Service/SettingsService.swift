//
//  SettingsService.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import Foundation

extension Service {
    
    // MARK: Read
    func getCurrencies() async throws -> [Currency] {
        return Currency.convertFromDBModel(try await repository.getCurrencies())
    }
    
    func getIcons() async throws -> [Icon] {
        return Icon.convertFromDBModel(try await repository.getIcons())
    }
    
    enum ApplicationType: String {
        case ios, server
    }
    
    func getVersion(_ applicationType: ApplicationType) async throws -> (String, String) {
        let versionModel = try await apiManager.GetVersion(applicationType.rawValue)
        return (versionModel.version, versionModel.build)
    }
}
