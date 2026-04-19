//
//  CoinApp.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI
import OSLog
import Factory
import ProtoDefinitions
import SwiftProtobuf
import GRPCCore
import GRPCNIOTransportHTTP2
import GRPCProtobuf

private let logger = Logger(subsystem: "Coin", category: "Main")

@main
struct MyApp: App {
        
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
        
    @AppStorage("isDarkMode") var isDarkMode = defaultIsDarkMode
    
    @AppStorage("isErrorShowing") var isErrorShowing = false
    @AppStorage("errorTitle") var errorText: String = ""
    @AppStorage("errorDescription") var errorDescription: String = ""
    
    @State var alert: AlertModel?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .alert(item: $alert) { alert in
                    Alert(title:
                            Text(alert.title),
                          message:
                            Text(alert.message),
                          dismissButton:
                            .cancel(
                                Text(alert.buttonText),
                                action: {
                                    alert.callback()
                                }
                            )
                    )
                }
                .environment(AlertManager(handle: {
                    alertModel in self.alert = alertModel
                }))
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    @ObservationIgnored
    @Injected(\.service) private var service
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        Task {
            do {
                try await service.registerNotifications(token: token)
            } catch {
                logger.error("Не смогли обновить токен уведомлений пользователя")
            }
        }
    };

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
       print(error.localizedDescription)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }
}

extension Container {
    var service: Factory<Service> {
        Factory(self) {
            do {
//                #if DEBUG
//                #endif
                
                // 1. Создаём транспорт с NIO (адрес берётся из UserDefaults, иначе дефолтный)
                let grpcHost = UserDefaults.standard.string(forKey: "grpcHost") ?? defaultGrpcHost
                let grpcPort = UserDefaults.standard.integer(forKey: "grpcPort")
                let transport = try HTTP2ClientTransport.Posix(
                    target: .dns(host: grpcHost, port: grpcPort != 0 ? grpcPort : defaultGrpcPort),
                    transportSecurity: .tls  // ← было .plaintext
                )
                
                // ⚠️ transport нужно запустить (в фоне)
                Task.detached {
                    try await transport.connect()
                }
                
                // 2. Создаём GRPCClient с транспортом
                let grpcClient = GRPCClient(transport: transport)
                
                // 3. Создаём клиенты для всех эндпоинтов
                let transactionClient = Transaction_TransactionEndpoint.Client(wrapping: grpcClient)
                let accountClient = Account_AccountEndpoint.Client(wrapping: grpcClient)
                let accountGroupClient = AccountGroup_AccountGroupEndpoint.Client(wrapping: grpcClient)
                let authClient = Auth_AuthEndpoint.Client(wrapping: grpcClient)
                let settingsClient = Settings_SettingsEndpoint.Client(wrapping: grpcClient)
                let tagClient = Tag_TagEndpoint.Client(wrapping: grpcClient)
                let userClient = User_UserEndpoint.Client(wrapping: grpcClient)
                
                // 4. Создаём менеджеры с gRPC клиентами
                let authManager = AuthManager(authClient: authClient)
                let networkManager = NetworkManager(authManager: authManager)
                let apiManager = APIManager(
                    networkManager: networkManager,
                    authClient: authClient,
                    transactionClient: transactionClient,
                    accountClient: accountClient,
                    accountGroupClient: accountGroupClient,
                    userClient: userClient,
                    tagClient: tagClient,
                    settingsClient: settingsClient
                )
                
                let sqlite = try SQLite()
                let repository = Repository(sqlite: sqlite)
                
                let taskManager = TaskManager(repository: repository, apiManager: apiManager)
                return Service(repository: repository, apiManager: apiManager, taskManager: taskManager, authManager: authManager)
            } catch {
                fatalError("Произошла ошибка при инициализации зависимости Service \(error)")
            }
        }.singleton
    }
    
    var alertManager: Factory<AlertManager> {
        return Factory(self) { return AlertManager() }.singleton
    }
}

struct AlertModel: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let buttonText: String
    let callback: () -> Void
}

@Observable
class AlertManager {
    
    init() {
        self.handle = { _ in }
    }
    
    let handle: (AlertModel) -> Void
    
    func error(
        _ error: Error,
        title: String = "Произошла ошибка",
        buttonText: String = "OK",
        callback: @escaping () -> Void = {},
        file: String = #file,
        line: Int = #line
    ) {
        logger.error("\(file):\(line)\n\(error)")
        handle(AlertModel(title: title, message: error.localizedDescription, buttonText: buttonText, callback: callback))
    }
    
    func warn(
        title: String,
        message: String,
        buttonText: String = "OK",
        callback: @escaping () -> Void = {},
        file: String = #file,
        line: Int = #line
    ) {
        logger.error("\(file):\(line)\n\(title)\n\(message)")
        handle(AlertModel(title: title, message: message, buttonText: buttonText, callback: callback))
    }
    
    init(handle: @escaping (AlertModel) -> Void) {
        self.handle = handle
    }
}
