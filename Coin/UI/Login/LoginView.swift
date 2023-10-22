//
//  LoginView.swift
//  Coin
//
//  Created by Илья on 20.10.2022.
//

import SwiftUI

struct LoginView: View {
    
    @AppStorage("isLogin") var isLogin: Bool = false
    @AppStorage("accessToken") var accessToken: String?
    @AppStorage("refreshToken") var refreshToken: String?
    
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
        
        AuthAPI().Auth(req: AuthRequest(email: login, password: password)) { response, error in
            
            if let err = error {
                appSettings.showErrorAlert(error: err)
                
            } else if let response = response {
                accessToken = response.token.accessToken
                refreshToken = response.token.refreshToken
                isLogin = true
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(AppSettings())
}
