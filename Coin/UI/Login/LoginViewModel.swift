//
//  LoginViewModel.swift
//  Coin
//
//  Created by Илья on 20.10.2022.
//

import SwiftUI


class LoginViewModel: ObservableObject {
    
    @Published var login = ""
    @Published var password = ""
    
    @Published var errDescription = ""
    @Published var errAlertShowing = false
    
    func auth(_ settings: AppSettings) {
        
        UserAPI().Auth(req: AuthRequest(email: login, password: password)) { response, error in
            
            if let err = error {
                settings.showErrorAlert(error: err)
                
            } else if let response = response {
                Defaults.accessToken = response.accessToken
                Defaults.refreshToken = response.refreshToken
                settings.isLogin = true
            }
        }
    }
}

