//
//  Settings.swift
//  Coin
//
//  Created by Илья on 16.01.2024.
//

import SwiftUI

enum SettingsRoute {
    case tasksList
}

struct Settings: View {
    
    @Environment(AlertManager.self) var alert
    @AppStorage("isDarkMode") private var isDarkMode = defaultIsDarkMode
    @AppStorage("apiBasePath") private var apiBasePath = defaultApiBasePath
    @Binding var path: NavigationPath
    
    @State var shouldDisableUI = false
    @State var shouldShowProgress = false
    @State var shouldShowAlert = false
    @State var differences: String? = nil
    
    @State private var vm = SettingsViewModel()
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $isDarkMode) {
                    Label("Темная тема", systemImage: isDarkMode ? "moon.fill" : "sun.max.fill")
                        .foregroundColor(.primary)
                }
            }
#if DEV
            Group {
                Section(header: Text("Инструменты разработчика")) {
                    HStack {
                        TextField("", text: $apiBasePath)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Button { apiBasePath = defaultApiBasePath } label: { Text("По умолчанию") }
                    }
                }
                Section {
                    Button {
                        Task {
                            shouldDisableUI = true
                            shouldShowProgress = true
                            defer {
                                shouldShowProgress = false
                                shouldDisableUI = false
                            }
                            do {
                                differences = try await vm.compareLocalAndServerData()
                            } catch {
                                alert(error)
                            }
                            shouldShowAlert = true
                        }
                    } label: {
                        if !shouldShowProgress {
                            Text("Сравнить данные с сервером")
                        } else {
                            ProgressView()
                        }
                    }
                    if let differences {
                        ShareLink("Скачать несовпадения", item: differences)
                    }
                }
                .frame(maxWidth: .infinity)
                Section {
                    NavigationLink("Показать все задачи", value: SettingsRoute.tasksList)
                }
                .frame(maxWidth: .infinity)
                .alert(isPresented: $shouldShowAlert) {
                    Alert(title:
                            Text(differences == nil ? "Все данные совпадают" : "Данные не совпадают"),
                          message:
                            Text(differences != nil ? "Вы можете скачать несовпадающие данные" : ""),
                          dismissButton:
                            .cancel(Text("OK"))
                    )
                }
            }
            .disabled(shouldDisableUI)
#endif
            Section(footer:
                VStack {
                    Text("Version \(vm.appVersion) (Build \(vm.appBuildNumber))")
                    Text("Server version \(vm.serverVersion) (Build \(vm.serverBuildNumber))")
                }
                .frame(maxWidth: .infinity)
            ) {}
        }
        .task {
            do {
                try await vm.load()
            } catch {
                
            }
        }
    }
}

#Preview {
    Settings(path: .constant(NavigationPath()))
        .environment(AlertManager(handle: {_ in }))
}
