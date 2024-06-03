//
//  DeveloperTools.swift
//  Coin
//
//  Created by Илья on 02.06.2024.
//

import SwiftUI

enum DeveloperToolsRoute {
    case tasksList
}

struct DeveloperTools: View {
    
    @State private var vm = DeveloperToolsViewModel()
    
    @AppStorage("apiBasePath") private var apiBasePath = defaultApiBasePath
    @Environment(AlertManager.self) var alert
    
    @State var shouldDisableUI = false
    @State var shouldShowProgress = false
    @State var shouldShowAlert = false
    
    @State var differences: String? = nil
    
    var isProdAPI: Bool {
        apiBasePath == defaultApiBasePath
    }

    
    
    var body: some View {
        Form {
            Group {
                Section {
                    Text(isProdAPI ? "Продакшн окружение" : "Тестовое окружение")
                        .foregroundColor(isProdAPI ? .red : .yellow)
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
                    NavigationLink("Показать все задачи", value: DeveloperToolsRoute.tasksList)
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
        }
        .navigationTitle("Разработчик")
    }
}

#Preview {
    DeveloperTools()
}
