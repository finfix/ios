//
//  LoginView.swift
//  Coin
//
//  Created by Илья on 20.10.2022.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Coin", category: "Login")

struct LoginView: View {
    
    private enum Mode {
        case login, register
    }
    
    private enum Field: Hashable {
        case name, login, password
    }
    
    @AppStorage("isLogin") var isLogin: Bool = false
    @AppStorage("accessToken") var accessToken: String?
    @AppStorage("refreshToken") var refreshToken: String?
    @FocusState private var focusedField: Field?
    
    @State private var mode: Mode = .login
    @State private var login = ""
    @State private var password = ""
    @State private var name = ""
    @State var isShowPassword = false
    @State private var shouldDisableUI = false
    @State private var shouldShowProgress = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if mode == .register {
                        TextField("Имя", text: $name)
                            .focused($focusedField, equals: .name)
                            .textContentType(.givenName)
                            .onSubmit { focusedField = .login }
                            .submitLabel(.next)
                    }
                    TextField("Email", text: $login)
                        .focused($focusedField, equals: .login)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textContentType(.emailAddress)
                        .onSubmit { focusedField = .password }
                        .submitLabel(.next)
                    HStack {
                        Group {
                            if !isShowPassword {
                                SecureField("Password", text: $password)
                            } else {
                                TextField("Password", text: $password)
                            }
                        }
                        .submitLabel(.go)
                        .focused($focusedField, equals: .password)
                        .textContentType(.password)
                        .onSubmit {
                            Task {
                                shouldDisableUI = true
                                shouldShowProgress = true
                                
                                switch mode {
                                case .login: await auth()
                                case .register: await register()
                                }
                                
                                shouldDisableUI = false
                                shouldShowProgress = false
                            }
                        }
                        
                        Button {
                            isShowPassword.toggle()
                        } label: {
                            Image(systemName: "eye")
                                .accentColor(.secondary)
                                .symbolVariant(isShowPassword ? .none : .slash)
                                .contentTransition(.symbolEffect(.replace))
                        }
                    }
                }
                Section {
                    Button {
                        Task {
                            shouldDisableUI = true
                            shouldShowProgress = true
                            
                            switch mode {
                            case .login: await auth()
                            case .register: await register()
                            }
                            
                            shouldDisableUI = false
                            shouldShowProgress = false
                        }
                    } label: {
                        if !shouldShowProgress{
                            Text(mode == .login ? "Войти" : "Зарегистрироваться")
                        } else {
                            ProgressView()
                        }
                    }
                } footer: {
                    if mode == .login {
                        HStack {
                            Text("Нет аккаунта?")
                            Button("Зарегистрироваться") {
                                withAnimation {
                                    mode = .register
                                }
                            }
                        }
                        .padding()
                        .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .contentMargins(.top, 200)
            .navigationTitle(mode == .login ? "Вход" : "Регистрация")
            .toolbar {
                if mode == .register {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Назад") {
                            withAnimation {
                                mode = .login
                            }
                        }
                    }
                }
            }
        }
        .disabled(shouldDisableUI)
    }
    
    func auth() async {
        do {
            let response = try await AuthAPI().Auth(req: AuthReq(email: login, password: password))
            accessToken = response.token.accessToken
            refreshToken = response.token.refreshToken
            isLogin = true
        } catch {
            showErrorAlert("\(error)")
            logger.error("\(error)")
        }
    }
    
    func register() async {
        do {
            let response = try await AuthAPI().Register(req: RegisterReq(email: login, password: password, name: name))
            accessToken = response.token.accessToken
            refreshToken = response.token.refreshToken
            isLogin = true
        } catch {
            showErrorAlert("\(error)")
            logger.error("\(error)")
        }
    }
}

#Preview {
    LoginView()
}
