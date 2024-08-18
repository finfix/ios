//
//  SettingsViewModel.swift
//  Coin
//
//  Created by Илья on 19.04.2024.
//

import Foundation
import Factory

@Observable
class SettingsViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
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
        (serverVersion, serverBuildNumber) = try await service.getVersion(.server)
    }
}
