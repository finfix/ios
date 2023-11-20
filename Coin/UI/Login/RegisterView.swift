//
//  RegisterView.swift
//  Coin
//
//  Created by Илья on 24.10.2023.
//

import SwiftUI

struct RegisterView: View {
    
    @AppStorage("isLogin") var isLogin: Bool = false
    @AppStorage("accessToken") var accessToken: String?
    @AppStorage("refreshToken") var refreshToken: String?
    
    @Binding var isSignUpOpen: Bool
    @State var login = ""
    @State var password = ""
    @State var name = ""
    
    var body: some View {
        VStack {
            
            TextField("Имя", text: $name)
                .modifier(CustomTextField())
                .textContentType(.givenName)
            
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
            
            Button("Войти") {
                register()
            }
            .modifier(CustomButton())
        }
        .navigationTitle("Регистрация")
    }
    
    func register() {
        Task {
            do {
                let response = try await AuthAPI().Register(req: RegisterReq(email: login, password: password, name: name))
                accessToken = response.token.accessToken
                refreshToken = response.token.refreshToken
                isLogin = true
                isSignUpOpen = false
            } catch {
                debugLog(error)
            }
        }
    }
}

#Preview {
    RegisterView(isSignUpOpen: .constant(true))
}
