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
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .textContentType(.emailAddress)
            
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
        
        AuthAPI().Register(req: RegisterReq(email: login, password: password, name: name)) { response, error in
            
            if let err = error {
                Alerter().showErrorAlert(error: err)
            } else if let response = response {
                accessToken = response.token.accessToken
                refreshToken = response.token.refreshToken
                isLogin = true
                isSignUpOpen = false
            }
        }
        
       
    }
}

#Preview {
    RegisterView(isSignUpOpen: .constant(true))
}
