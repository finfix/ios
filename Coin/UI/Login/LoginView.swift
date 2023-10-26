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
    @State var isSignUpOpen = false
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Email", text: $login)
                    .modifier(CustomTextField())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textContentType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .modifier(CustomTextField())
                    .textContentType(.password)
                
                HStack {
                    Text("Нет аккаунта?")
                    Button("Зарегистрироваться") {
                        isSignUpOpen = true
                    }
                    .buttonStyle(.borderless)
                    .navigationDestination(isPresented: $isSignUpOpen) {
                        RegisterView(isSignUpOpen: $isSignUpOpen, login: login, password: password)
                    }
                }
                
                Button("Войти") {
                    auth()
                }
                .modifier(CustomButton())
            }
            .navigationTitle("Вход")
        }
    }
    
    func auth() {
        
        AuthAPI().Auth(req: AuthRequest(email: login, password: password)) { response, error in
            
            if let err = error {
                Alerter().showErrorAlert(error: err)
                
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
}
