//
//  LoginView.swift
//  Coin
//
//  Created by Илья on 20.10.2022.
//

import SwiftUI
import OSLog
import DeviceKit

private let logger = Logger(subsystem: "Coin", category: "Login")

enum LoginRoute {
    case settings
    case developerTools
}

struct LoginView: View {
    
    private enum Mode {
        case login, register
    }
    
    private enum Field: Hashable {
        case name, login, password
    }
    
    @State private var service = Service.shared
    @State private var path = PathSharedState()
    @Environment(AlertManager.self) private var alert
    
    @AppStorage("isLogin") var isLogin: Bool = false
    @AppStorage("accessToken") var accessToken: String?
    @AppStorage("refreshToken") var refreshToken: String?
    @AppStorage("isDeveloperMode") var isDevMode = false
    @FocusState private var focusedField: Field?
    
    @State private var mode: Mode = .login
    @State private var login = ""
    @State private var password = ""
    @State private var name = ""
    @State var isShowPassword = false
    @State private var shouldDisableUI = false
    @State private var shouldShowProgress = false
    
    var body: some View {
        @Bindable var path = path
        NavigationStack(path: $path.path) {
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
                                    .textContentType(.password)
                            } else {
                                TextField("Password", text: $password)
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
        .disabled(shouldDisableUI)
    }
    
    func auth() async {
        do {
            guard let bundleID = Bundle.main.bundleIdentifier else {
                throw ErrorModel(humanText: "Не смогли получить Bundle Identifier приложения")
            }
            let response = try await AuthAPI().Auth(req: AuthReq(
                email: login,
                password: password,
                application: getApplicationInformation(),
                device: getDeviceInformation()
            ))
            accessToken = response.token.accessToken
            refreshToken = response.token.refreshToken
            try await service.sync()
            isLogin = true
        } catch {
            alert(error)
        }
    }
    
    func register() async {
        do {
            guard let bundleID = Bundle.main.bundleIdentifier else {
                throw ErrorModel(humanText: "Не смогли получить Bundle Identifier приложения")
            }
            let response = try await AuthAPI().Register(req: RegisterReq(
                email: login,
                password: password,
                name: name,
                application: getApplicationInformation(),
                device: getDeviceInformation()
            ))
            accessToken = response.token.accessToken
            refreshToken = response.token.refreshToken
            try await service.sync()
            isLogin = true
        } catch {
            alert(error)
        }
    }
}

#Preview {
    LoginView()
        .environment(AlertManager(handle: {_ in }))
}
