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
    @AppStorage("debugPanelClose") private var debugPanelClose = false
    @AppStorage("debugManualDrag") private var debugManualDrag = false
    @AppStorage("debugShowStaticLocations") private var debugShowStaticLocations = false
    private var authStorage = AuthStorage.shared
    private var syncState = SyncStateStorage.shared
    @Environment(AlertManager.self) var alert
    @Environment(AccountGroupSharedState.self) var selectedAccountGroup

    @State var shouldDisableUI = false
    @State var shouldShowProgress = false
    @State var shouldShowAlert = false
    @State var differences: String? = nil
    @State var shouldShowIncrementalSyncProgress = false

    // Сворачиваемые секции — по умолчанию свёрнуты, чтобы экран разработчика не был стеной
    // текста; разворачивается только тот инструмент, который сейчас реально нужен.
    @State private var isGRPCExpanded = false
    @State private var isDataExpanded = false
    @State private var isAutoSyncExpanded = false
    @State private var isAuthExpanded = false
    @State private var debugAuthLogin = ""
    @State private var debugAuthPassword = ""
    @State private var isBridgeExpanded = false
    @State private var pendingLinkedTransfers: [PendingLinkedTransfer] = []
    @State private var linkedAccounts: [Account] = []

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
                        NavigationLink("Показать все задачи", value: DeveloperToolsRoute.tasksList)
                        Toggle("Дебаг закрытия панели счетов", isOn: $debugPanelClose)
                        Toggle("Дебаг ручного драга счетов", isOn: $debugManualDrag)
                        Toggle("Показывать static locations", isOn: $debugShowStaticLocations)
                    }
                }
                .frame(maxWidth: .infinity)

                // MARK: Инкрементальная синхронизация (Sync/ConfirmSync)
                Section {
                    DisclosureGroup("Автосинхронизация", isExpanded: $isAutoSyncExpanded) {
                        Text("Тикает раз в минуту (ContentView) и после 409 на мутации. Не путать со \"Сравнить данные с сервером\" выше — это про полный hard sync.")
                            .font(.caption)
                            .foregroundColor(.secondary)
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

                // MARK: Счета-мосты (без скоупа по группе — прямой дамп локальных таблиц)
                Section {
                    DisclosureGroup("Счета-мосты (дебаг)", isExpanded: $isBridgeExpanded) {
                        HStack {
                            Text("Текущая выбранная группа")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(selectedAccountGroup.selectedAccountGroup.name) — \(selectedAccountGroup.selectedAccountGroup.id.uuidString.prefix(8))")
                        }
                        .font(.caption)
                        Text("Связанные счета (linkedAccountID != nil)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if linkedAccounts.isEmpty {
                            Text("Нет ни одного связанного счёта")
                                .foregroundColor(.orange)
                        } else {
                            ForEach(linkedAccounts) { account in
                                HStack {
                                    Text(account.name)
                                    Spacer()
                                    Text(account.linkedAccountID?.uuidString.prefix(8) ?? "")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        Text("Все PendingLinkedTransfer (без фильтра по группе)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if pendingLinkedTransfers.isEmpty {
                            Text("Локально нет ни одной записи")
                                .foregroundColor(.orange)
                        } else {
                            ForEach(pendingLinkedTransfers) { transfer in
                                VStack(alignment: .leading) {
                                    Text("status: \(transfer.status.rawValue)")
                                    Text("accountGroupID: \(transfer.accountGroupID.uuidString.prefix(8))")
                                        .foregroundColor(.secondary)
                                    Text("targetAccountID: \(transfer.targetAccountID.uuidString.prefix(8))")
                                        .foregroundColor(.secondary)
                                }
                                .font(.caption)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .task {
                    do {
                        linkedAccounts = try await vm.allAccountsWithLinks()
                        for try await transfers in vm.observeAllPendingLinkedTransfers() {
                            pendingLinkedTransfers = transfers
                        }
                    } catch {}
                }

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
