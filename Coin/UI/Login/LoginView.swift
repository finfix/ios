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
            Form {
                Section {
                    TextField("Email", text: $login)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textContentType(.emailAddress)
                }
                Section {
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }
                Section {
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
                }
                Section {
                    Button("Войти") {
                        auth()
                    }
                }
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
