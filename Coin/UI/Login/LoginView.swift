//
//  LoginView.swift
//  Coin
//
//  Created by Илья on 20.10.2022.
//

import SwiftUI

struct LoginView: View {
        
    @State var login = ""
    @State var password = ""
    
    @Environment(AppSettings.self) var appSettings
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Email", text: $login)
                    .modifier(CustomTextField())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textContentType(.username)
                SecureField("Password", text: $password)
                    .modifier(CustomTextField())
                    .textContentType(.password)
                Button {
                    auth()
                } label: {
                    Text("Sign In")
                }
                .modifier(CustomButton())
            }
        }
    }
    
    func auth() {
        
        UserAPI().Auth(req: AuthRequest(email: login, password: password)) { response, error in
            
            if let err = error {
                appSettings.showErrorAlert(error: err)
                
            } else if let response = response {
                Defaults.accessToken = response.token.accessToken
                Defaults.refreshToken = response.token.refreshToken
                appSettings.isLogin = true
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(AppSettings())
}
