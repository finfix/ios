//
//  ContentView.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI
import Factory
import OSLog

private let logger = Logger(subsystem: "Coin", category: "ContentView")

struct ContentView: View {
    
    @ObservationIgnored
    @Injected(\.service) private var service
    @Environment(AlertManager.self) var alert
    @Environment(\.scenePhase) private var scenePhase
    private var authStorage = AuthStorage.shared

    // Держит SubscribeToSync-стрим открытым ТОЛЬКО пока приложение на переднем плане — в фоне
    // iOS всё равно рвёт сокет за секунды, так что смысла в нём там нет, а periodic-таймер ниже
    // не работает в фоне точно так же. Мгновенный отклик — бонус активного использования, не
    // замена периодическому incrementalSync() (остаётся как fallback на случай обрыва стрима).
    @State private var syncSubscriptionTask: Task<Void, Never>?

    private func startSyncSubscription() {
        logger.debug("startSyncSubscription: запускаем")
        syncSubscriptionTask?.cancel()
        syncSubscriptionTask = Task {
            do {
                for try await _ in service.subscribeToSyncNotifications() {
                    do {
                        try await service.incrementalSync()
                    } catch {
                        logger.warning("SubscribeToSync → incrementalSync: \(error)")
                    }
                }
            } catch is CancellationError {
                // Обычное завершение при уходе в фон/переподключении — не ошибка.
            } catch {
                logger.warning("SubscribeToSync: обрыв стрима — \(error)")
            }
        }
    }

    var body: some View {
        Group {
            if authStorage.isLogin {
                AppTabView()
                    .task {
                        Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
                            Task {
                                do {
                                    try await service.taskManager.executeDBTasks()
                                } catch {
                                    logger.warning("\(error)")
                                }
                            }
                        }
                        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                            Task {
                                do {
                                    try await service.incrementalSync()
                                } catch {
                                    logger.warning("\(error)")
                                }
                            }
                        }
                        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                            Task {
                                do {
                                    try await service.checkMonthChange()
                                } catch {
                                    logger.warning("\(error)")
                                }
                            }
                        }
                        if scenePhase == .active {
                            startSyncSubscription()
                        }
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        if newPhase == .active {
                            startSyncSubscription()
                        } else {
                            syncSubscriptionTask?.cancel()
                            syncSubscriptionTask = nil
                        }
                    }
            } else {
                LoginView()
            }
        }
        .task {
            do {
                
                // Получаем последнюю поддерживаемую версию iOS приложения
                let (serverVersion, _) = try await service.getVersion(.ios)
                
                // Получаем версию приложения
                guard let localVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
                    alert.error(ErrorModel(humanText: "Не смогли получить версию приложения"))
                    return
                }
                
                // Если локальная версия не выше и не равна минимально поддерживаемой версии из сервера
                if try !isLocalVersionHigherOrEqual(localVersion: localVersion, targetVersion: serverVersion) {
                    
                    // Показываем алерт
                    alert.warn(
                        title: "Необходимо обновиться",
                        message: "Вышло новое обновление",
                        buttonText: "Обновиться",
                        callback: {
                            print("TODO: Обновляемся")
                        }
                    )
                }
            } catch {
                alert.error(error)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AlertManager(handle: {_ in }))
}

func isLocalVersionHigherOrEqual(localVersion: String, targetVersion: String) throws -> Bool {
    
    let (localVersionMajor, localVersionMinor, localVersionPatch) = try parseVersion(version: localVersion)

    let (targetVersionMajor, targetVersionMinor, targetVersionPatch) = try parseVersion(version: targetVersion)

    if localVersionMajor > targetVersionMajor { // Мажорная версия выше

        return true

    } else if localVersionMajor == targetVersionMajor { // Мажорная версия равна

        if localVersionMinor > targetVersionMinor { // Минорная версия выше

            return true

        } else if localVersionMinor == targetVersionMinor { // Минорная версия равна

            if localVersionPatch >= targetVersionPatch { // Патч версия выше или равна

                return true

            }
        }
    }

    return false
}

func parseVersion(version: String) throws -> (Int, Int, Int) {
    
    let version = removeNonNumericAndDot(from: version)
    
    // Разбиваем версию на составляющие
    let substrs = version.split(separator: ".")

    if substrs.count != 3 {
        throw ErrorModel(humanText: "В пришедшей версии нет трех чисел")
    }

    // Преобразуем строки в числа
    var versions: [Int] = []
    for substr in substrs {
        guard let version = Int(substr) else {
            throw ErrorModel(humanText: "Не можем распарсить число")
        }
        versions.append(version)
    }

    return (versions[0], versions[1], versions[2])
}

func removeNonNumericAndDot(from input: String) -> String {
    let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
    return input.filter { String($0).rangeOfCharacter(from: allowedCharacters) != nil }
}
