//
//  LoginView.swift
//  Coin
//
//  Created by Илья on 20.10.2022.
//

import SwiftUI
import OSLog
import DeviceKit
import Factory

private let logger = Logger(subsystem: "Coin", category: "Login")

enum LoginRoute {
    case settings
    case developerTools
}

struct LoginView: View {
    
    @State private var path = PathSharedState()
    @Environment(AlertManager.self) private var alert
    @State private var vm = LoginViewModel()
    
    @AppStorage("isDeveloperMode") var isDevMode = false
    @FocusState var focusedField: Field?
    
    enum Field: Hashable {
        case name, login, password
    }
    
    var body: some View {
        @Bindable var path = path
        NavigationStack(path: $path.path) {
            Form {
                Section {
                    if vm.mode == .register {
                        TextField("Имя", text: $vm.name)
                            .focused($focusedField, equals: .name)
                            .textContentType(.givenName)
                            .onSubmit { focusedField = .login }
                            .submitLabel(.next)
                    }
                    TextField("Email", text: $vm.login)
                        .focused($focusedField, equals: .login)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textContentType(.emailAddress)
                        .onSubmit { focusedField = .password }
                        .submitLabel(.next)
                    HStack {
                        Group {
                            if !vm.isShowPassword {
                                SecureField("Password", text: $vm.password)
                                    .textContentType(.password)
                            } else {
                                TextField("Password", text: $vm.password)
                                    .textContentType(.password)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                        }
                        .submitLabel(.go)
                        .focused($focusedField, equals: .password)
                        .textContentType(.password)
                        .onSubmit {
                            Task {
                                do {
                                    try await vm.auth()
                                } catch {
                                    alert(error)
                                }
                            }
                        }
                        
                        Button {
                            vm.isShowPassword.toggle()
                        } label: {
                            Image(systemName: "eye")
                                .accentColor(.secondary)
                                .symbolVariant(vm.isShowPassword ? .none : .slash)
                                .contentTransition(.symbolEffect(.replace))
                        }
                    }
                }
                Section {
                    Button {
                        Task {
                            do {
                                try await vm.auth()
                            } catch {
                                alert(error)
                            }
                        }
                    } label: {
                        if !vm.shouldShowProgress{
                            Text(vm.mode == .login ? "Войти" : "Зарегистрироваться")
                        } else {
                            ProgressView()
                        }
                    }
                } footer: {
                    if vm.mode == .login {
                        HStack {
                            Text("Нет аккаунта?")
                            Button("Зарегистрироваться") {
                                withAnimation {
                                    vm.mode = .register
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
            .navigationTitle(vm.mode == .login ? "Вход" : "Регистрация")
            .toolbar {
#if DEV
                if isDevMode {
                    ToolbarItem {
                        NavigationLink(value: LoginRoute.developerTools) {
                            Image(systemName: "hammer.fill")
                        }
                    }
                }
#endif
                ToolbarItem {
                    NavigationLink(value: LoginRoute.settings) {
                        Image(systemName: "gearshape")
                    }
                }
                if vm.mode == .register {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Назад") {
                            withAnimation {
                                vm.mode = .login
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: LoginRoute.self) { screen in
                switch screen {
                case .settings: Settings()
                case .developerTools: DeveloperTools()
                }
            }
            .navigationDestination(for: DeveloperToolsRoute.self) { screen in
                switch screen {
                case .tasksList: TasksList()
                }
            }
            .navigationDestination(for: TasksListRoute.self) { screen in
                switch screen {
                case .taskDetails(let task): TaskDetails(task: task)
                }
            }
        }
        .environment(path)
        .disabled(vm.shouldDisableUI)
    }
}

#Preview {
    LoginView()
        .environment(AlertManager(handle: {_ in }))
}
