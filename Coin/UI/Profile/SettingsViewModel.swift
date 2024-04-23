//
//  SettingsViewModel.swift
//  Coin
//
//  Created by Илья on 19.04.2024.
//

import Foundation

@Observable
class SettingsViewModel {
    private let service = Service.shared
    
    var appVersion: String {
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return appVersion
        }
        return "Unknown"
    }
    
    var appBuildNumber: String {
        if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return buildNumber
        }
        return "Unknown"
    }
    
    var serverVersion: String = "Unknown"
    var serverBuildNumber: String = "Unknown"
    
    func load() async throws {
        (serverVersion, serverBuildNumber) = try await service.getServerVersion()
    }
    
    func compareLocalAndServerData() async throws -> String? {
        return try await service.compareLocalAndServerData()
    }
}
