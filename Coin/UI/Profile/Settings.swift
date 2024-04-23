//
//  Settings.swift
//  Coin
//
//  Created by Илья on 16.01.2024.
//

import SwiftUI

struct Settings: View {
    
    @Environment(AlertManager.self) var alert
    @AppStorage("isDarkMode") private var isDarkMode = defaultIsDarkMode
    @AppStorage("isDevMode") private var isDevMode = defaultIsDevMode
    @AppStorage("apiBasePath") private var apiBasePath = defaultApiBasePath
    
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
            Section(header: Text("Инструменты разработчика")) {
                Toggle(isOn: $isDevMode) {
                    Label("Режим разработчика", systemImage: "hammer.fill")
                        .foregroundColor(.primary)
                }
                .onChange(of: isDevMode) { _, newValue in
                    if newValue == true {
                        apiBasePath = defaultApiBasePath
                    }
                }
            }
            if isDevMode {
                Section {
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
            }
            Section(footer:
                VStack {
                    Text("Version \(vm.appVersion) (Build \(vm.appBuildNumber))")
                    Text("Server version \(vm.serverVersion) (Build \(vm.serverBuildNumber))")
                }
                .frame(maxWidth: .infinity)
            ) {}
        }
        .disabled(shouldDisableUI)
        .alert(isPresented: $shouldShowAlert) {
            Alert(title:
                    Text(differences == nil ? "Все данные совпадают" : "Данные не совпадают"),
                  message:
                    Text(differences != nil ? "Вы можете скачать несовпадающие данные" : ""),
                  dismissButton:
                    .cancel(Text("OK"))
            )
        }
        .task {
            do {
                try await vm.load()
            } catch {
                alert(error)
            }
        }
    }
}

#Preview {
    Settings()
        .environment(AlertManager(handle: {_ in }))
}
