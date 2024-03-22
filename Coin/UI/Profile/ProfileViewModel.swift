//
//  ProfileViewModel.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation

@Observable
class ProfileViewModel {
    private let service = Service.shared
    
    func sync() async {
        do {
            try await service.sync()
        } catch {
            do {
                try service.deleteAllData()
            } catch {
                showErrorAlert("\(error)")
            }
            showErrorAlert("\(error)")
        }
    }
}
