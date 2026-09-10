//
//  DeveloperTools.swift
//  Coin
//
//  Created by Илья on 02.06.2024.
//

import SwiftUI


struct DeveloperTools: View {

    @State private var vm = DeveloperToolsViewModel()

    @AppStorage("grpcHost") private var grpcHost = defaultGrpcHost
    @AppStorage("grpcPort") private var grpcPort = defaultGrpcPort
    @AppStorage("debugPanelClose") private var debugPanelClose = false
    @AppStorage("debugManualDrag") private var debugManualDrag = false
    @AppStorage("debugShowStaticLocations") private var debugShowStaticLocations = false
    private var authStorage = AuthStorage.shared
    private var syncState = SyncStateStorage.shared
    @Environment(AlertManager.self) var alert

    @State var shouldDisableUI = false
    @State var shouldShowProgress = false
    @State var shouldShowAlert = false
    @State var differences: String? = nil
    @State var shouldShowIncrementalSyncProgress = false

    // Сворачиваемые секции — по умолчанию свёрнуты, чтобы экран разработчика не был стеной
    // текста; разворачивается только тот инструмент, который сейчас реально нужен.
    @State private var isGRPCExpanded = false
    @State private var isDataExpanded = false
    @State private var isVisualDebugExpanded = false
    @State private var isAutoSyncExpanded = false
    @State private var isAuthExpanded = false
    @State private var debugAuthLogin = ""
    @State private var debugAuthPassword = ""

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()

    var isDefaultGRPC: Bool {
        grpcHost == defaultGrpcHost && grpcPort == defaultGrpcPort
    }

    var body: some View {
        Form {
            Group {
                // MARK: gRPC
                Section {
                    DisclosureGroup("gRPC сервер", isExpanded: $isGRPCExpanded) {
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
                }

                // MARK: Данные
                Section {
                    DisclosureGroup("Данные", isExpanded: $isDataExpanded) {
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
                }
                .frame(maxWidth: .infinity)

                // MARK: Таски (очередь фоновой синхронизации)
                Section {
                    NavigationLink("Показать все задачи", value: DeveloperToolsRoute.tasksList)
                }

                // MARK: Визуальный дебаг
                Section {
                    DisclosureGroup("Визуальный дебаг", isExpanded: $isVisualDebugExpanded) {
                        Toggle("Дебаг закрытия панели счетов", isOn: $debugPanelClose)
                        Toggle("Дебаг ручного драга счетов", isOn: $debugManualDrag)
                        Toggle("Показывать static locations", isOn: $debugShowStaticLocations)
                    }
                }
                .frame(maxWidth: .infinity)

                // MARK: Инкрементальная синхронизация (Sync/ConfirmSync)
                Section {
                    DisclosureGroup("Автосинхронизация", isExpanded: $isAutoSyncExpanded) {
                        HStack {
                            Text("Чекпоинт (lastSyncedAuditLogID)")
                                .foregroundColor(.secondary)
                            Spacer()
                            CopyableIDText(id: "\(syncState.lastSyncedAuditLogID)")
                        }
                        HStack {
                            Text("Статус")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(vm.taskManager.incrementalSyncInProgress ? "Выполняется…" : "Простаивает")
                        }
                        if let startedAt = vm.taskManager.lastIncrementalSyncStartedAt {
                            HStack {
                                Text("Последний запуск")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(Self.dateFormatter.string(from: startedAt))
                            }
                        }
                        if let finishedAt = vm.taskManager.lastIncrementalSyncFinishedAt {
                            HStack {
                                Text("Последнее завершение")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(Self.dateFormatter.string(from: finishedAt))
                            }
                        }
                        if let summary = vm.taskManager.lastIncrementalSyncSummary {
                            HStack {
                                Text("Последний результат")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(summary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        if let conflictAt = vm.taskManager.lastConfirmSyncConflict {
                            HStack {
                                Text("Последний конфликт ConfirmSync")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(Self.dateFormatter.string(from: conflictAt))
                                    .foregroundColor(.yellow)
                            }
                        }
                        if let error = vm.taskManager.lastIncrementalSyncError {
                            HStack {
                                Text(error)
                                    .foregroundColor(.red)
                                    .copyableOnTap(error)
                            }
                        }
                        Button {
                            Task {
                                shouldShowIncrementalSyncProgress = true
                                defer { shouldShowIncrementalSyncProgress = false }
                                do {
                                    try await vm.triggerIncrementalSync()
                                } catch {
                                    alert.error(error)
                                }
                            }
                        } label: {
                            if shouldShowIncrementalSyncProgress {
                                ProgressView()
                            } else {
                                Text("Синхронизировать сейчас")
                            }
                        }
                        .disabled(shouldShowIncrementalSyncProgress || vm.taskManager.incrementalSyncInProgress)
                        Button(role: .destructive) {
                            vm.resetSyncCheckpoint()
                        } label: {
                            Text("Сбросить чекпоинт (полная пересинхронизация)")
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                // MARK: Авторизация
                Section {
                    DisclosureGroup("Авторизация", isExpanded: $isAuthExpanded) {
                        HStack {
                            Text("Device ID")
                                .foregroundColor(.secondary)
                            Spacer()
                            CopyableIDText(id: getDeviceInformation().deviceID)
                        }
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

                        Divider()

                        Text("Логин/пароль — получить новую пару токенов, БЕЗ sync()")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Логин", text: $debugAuthLogin)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textContentType(.username)
                        SecureField("Пароль", text: $debugAuthPassword)
                            .textContentType(.password)
                        Button("Получить токены") {
                            Task {
                                shouldDisableUI = true
                                defer { shouldDisableUI = false }
                                do {
                                    try await vm.authWithoutSync(login: debugAuthLogin, password: debugAuthPassword)
                                } catch {
                                    alert.error(error)
                                }
                            }
                        }
                        .disabled(debugAuthLogin.isEmpty || debugAuthPassword.isEmpty)
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
