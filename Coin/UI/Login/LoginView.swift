//
//  LoginView.swift
//  Coin
//
//  Created by Илья on 20.10.2022.
//

import SwiftUI

struct LoginView: View {
    
    @StateObject var vm = LoginViewModel()
    
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Email", text: $vm.login)
                    .modifier(CustomTextField())
                TextField("Password", text: $vm.password)
                    .modifier(CustomTextField())
                Button {
                    vm.auth(appSettings)
                    print(appSettings.isLogin)
                } label: {
                    Text("Sign In")
                }
                .modifier(CustomButton())
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    
    static var previews: some View {
        LoginView()
    }
}
