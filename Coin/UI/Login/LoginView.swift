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
                    .disableAutocorrection(true)
                    .textContentType(.emailAddress)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    #endif
                
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
        Task {
            do {
                let response = try await AuthAPI().Auth(req: AuthReq(email: login, password: password))
                accessToken = response.token.accessToken
                refreshToken = response.token.refreshToken
                isLogin = true
            } catch {
                debugLog(error)
            }
        }
    }
}

#Preview {
    LoginView()
}
