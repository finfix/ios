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

private let logger = Logger(subsystem: "Coin", category: "AlertManager")

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
        var message = error.localizedDescription
        let isDevMode = UserDefaults.standard.bool(forKey: "isDeveloperMode")
        if isDevMode {
            if let errorModel = error as? ErrorModel, !errorModel.error.isEmpty {
                message += "\n\n" + errorModel.error
            } else if !(error is ErrorModel) {
                message += "\n\n" + "\(error)"
            }
        }
        handle(AlertModel(title: title, message: message, buttonText: buttonText, callback: callback))
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
