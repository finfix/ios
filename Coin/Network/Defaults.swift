//
//  Defaults.swift
//  Coin
//
//  Created by Илья on 27.10.2023.
//

import Foundation

let defaultIsDarkMode = true
let defaultIsDevMode = false
#if DEV
let defaultGrpcHost = "grpc.dev.bonavii.com"
#else
let defaultGrpcHost = "grpc.bonavii.com"
#endif
let defaultGrpcPort = 443
