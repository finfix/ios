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
    
    @AppStorage("grpcHost") private var grpcHost = defaultGrpcHost
    @AppStorage("grpcPort") private var grpcPort = defaultGrpcPort
    private var authStorage = AuthStorage.shared
    @AppStorage("debugShowStaticLocations") private var debugShowStaticLocations = false
    @Environment(AlertManager.self) var alert
    
    @State var shouldDisableUI = false
    @State var shouldShowProgress = false
    @State var shouldShowAlert = false
    @State var differences: String? = nil
    
    var isDefaultGRPC: Bool {
        grpcHost == defaultGrpcHost && grpcPort == defaultGrpcPort
    }
    
    var body: some View {
        Form {
            Group {
                // MARK: gRPC
                Section(header: Text("gRPC сервер")) {
                    Text(isDefaultGRPC ? "Локальный сервер" : "Нестандартный адрес")
                        .foregroundColor(isDefaultGRPC ? .secondary : .yellow)
                    HStack {
                        Text("Host")
                            .foregroundColor(.secondary)
                        TextField(defaultGrpcHost, text: $grpcHost)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Port")
                            .foregroundColor(.secondary)
                        TextField(String(defaultGrpcPort), value: $grpcPort, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Button {
                            grpcHost = defaultGrpcHost
                            grpcPort = defaultGrpcPort
                        } label: {
                            Text("По умолчанию")
                        }
                        Spacer()
                        Button {
                            do {
                                try vm.reconnectGRPC(host: grpcHost, port: grpcPort)
                            } catch {
                                alert.error(error)
                            }
                        } label: {
                            Text("Переподключить")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                // MARK: Данные
                Section {
                    Button {
                        Task {
                            shouldDisableUI = true
                            shouldShowProgress = true
                            defer {
                                shouldShowProgress = false
                                shouldDisableUI = false
                            }
                            differences = nil
                            do {
                                differences = try await vm.compareLocalAndServerData()
                                shouldShowAlert = true
                            } catch {
                                // Если сравнение упало с ошибкой (например, есть незавершённые
                                // фоновые задачи), не показываем следом алерт "Все данные
                                // совпадают" — differences так и остался nil, хотя сравнение
                                // фактически не выполнялось.
                                alert.error(error)
                            }
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
                Section(header: Text("Отладка")) {
                    Toggle("Показывать staticLocations кружками", isOn: $debugShowStaticLocations)
                }
                Section {
                    TextField("Access token", text: Binding(
                        get: { authStorage.accessToken ?? "" },
                        set: { authStorage.accessToken = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Refresh token", text: Binding(
                        get: { authStorage.refreshToken ?? "" },
                        set: { authStorage.refreshToken = $0.isEmpty ? nil : $0 }
                    ))
                    Button("Принудительный рефреш токенов") {
                        Task {
                            shouldDisableUI = true
                            defer { shouldDisableUI = false }
                            do {
                                try await vm.forceRefreshTokens()
                            } catch {
                                alert.error(error)
                            }
                        }
                    }
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
