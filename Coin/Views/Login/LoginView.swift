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
            // NavigationLink {
            //     MainView()
            // } label: {
                Button {
                    UserAPI().Login(req: LoginRequest(login: vm.login, password: vm.password)) { response in
                        print("Авторизация прошла")
                        UserDefaults.standard.set(response.tokens.accessToken, forKey: "accessToken")
                        success = true
                    }
                } label: {
                    Text("Продолжить")
                }
                .modifier(CustomButton())
            // }

           

        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
