//
//  LoginView.swift
//  Coin
//
//  Created by Илья on 20.10.2022.
//

import SwiftUI
import SwiftData
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
    @Environment(\.modelContext) var modelContext
    @FocusState private var focusedField: Field?
    
    @State private var mode: Mode = .login
    @State private var login = ""
    @State private var password = ""
    @State private var name = ""
    @State var isShowPassword = false
    
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
                            switch mode {
                            case .login: auth()
                            case .register: register()
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
                    Button(mode == .login ? "Войти" : "Зарегистрироваться") {
                        switch mode {
                        case .login: auth()
                        case .register: register()
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
    }
    
    func auth() {
        Task {
            do {
                let response = try await AuthAPI().Auth(req: AuthReq(email: login, password: password))
                accessToken = response.token.accessToken
                refreshToken = response.token.refreshToken
                isLogin = true
                await LoadModelActor(modelContainer: modelContext.container).sync()
            } catch {
                logger.error("\(error)")
            }
        }
    }
    
    func register() {
        Task {
            do {
                let response = try await AuthAPI().Register(req: RegisterReq(email: login, password: password, name: name))
                accessToken = response.token.accessToken
                refreshToken = response.token.refreshToken
                isLogin = true
                await LoadModelActor(modelContainer: modelContext.container).sync()
            } catch {
                logger.error("\(error)")
            }
        }
    }
}

#Preview {
    LoginView()
}
