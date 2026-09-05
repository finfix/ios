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

struct AlertModel: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let buttonText: String
    let callback: () -> Void
}
