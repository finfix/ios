//
//  LoginView.swift
//  Coin
//
//  Created by Илья on 20.10.2022.
//

import SwiftUI

struct LoginView: View {
    
    @StateObject var vm = LoginViewModel()
    @State var success = false
    
    var body: some View {
        
        VStack {
            TextField("Логин", text: $vm.login)
                .modifier(CustomTextField())
            TextField("Пароль", text: $vm.password)
                .modifier(CustomTextField())
            
            NavigationLink(destination: MainView(), isActive: $success) {
                Button {
                    UserAPI().Auth(req: LoginRequest(email: "i", password: "qwerty")) { response, statusCode in
                        if statusCode != 200 || response == nil {
                            
                        }
                        UserDefaults.standard.set(response!.tokens.accessToken, forKey: "accessToken")
                        success = true
                    }
                } label: {
                    Text("Продолжить")
                        .modifier(CustomButton())
                }
                .alert
            }
        }
        .navigationBarHidden(true)
    }
}

struct LoginView_Previews: PreviewProvider {
    
    static var previews: some View {
        LoginView()
    }
}
