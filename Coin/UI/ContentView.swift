//
//  ContentView.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI
import Factory

struct ContentView: View {
    
    @AppStorage("isLogin") var isLogin: Bool = false
    @ObservationIgnored
    @Injected(\.service) private var service
    @Environment(AlertManager.self) var alert
    
    var body: some View {
        Group {
            if isLogin {
                AppTabView()
                    .task {
                        Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
                            service.taskManager.executeDBTasks()
                        }
                    }
            } else {
                LoginView()
            }
        }
        .task {
            do {
                let (serverVersion, serverBuild) = try await service.getVersion(.ios)
                let serverVersionParts = serverVersion.replacingOccurrences(of: "v", with: "").split(separator: ".")
                
                guard let localVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
                    alert(ErrorModel(humanText: "Не смогли получить версию приложения"))
                    return
                }
                let localVersionParts = localVersion.replacingOccurrences(of: "v", with: "").split(separator: ".")
                
                guard serverVersionParts.count == 3, localVersionParts.count == 3 else {
                    alert(ErrorModel(humanText: "Не смогли обработать версию с сервера или с телефона"))
                    return
                }
                
                for (i, localVersionPart) in localVersionParts.enumerated() {
                    let localVersionPartNumber = Int(localVersionPart)!
                    let serverVersionPartNumber = Int(serverVersionParts[i])!
                    if localVersionPartNumber < serverVersionPartNumber {
                        alert(
                            title: "Необходимо обновиться",
                            message: "Вышло новое обновление",
                            buttonText: "Обновиться",
                            callback: {
                                print("TODO: Обновляемся")
                            }
                        )
                    }
                }
            } catch {
                alert(error)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AlertManager(handle: {_ in }))
}
