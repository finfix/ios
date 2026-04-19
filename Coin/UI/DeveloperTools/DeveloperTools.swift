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
    @AppStorage("accessToken") private var accessToken: String = ""
    @AppStorage("refreshToken") private var refreshToken: String = ""
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
                            do {
                                differences = try await vm.compareLocalAndServerData()
                            } catch {
                                alert.error(error)
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
                Section {
                    TextField("Access token", text: $accessToken)
                    TextField("Refresh token", text: $refreshToken)
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
