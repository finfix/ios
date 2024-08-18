//
//  APIs.swift
//  Coin
//
//  Created by Илья on 17.10.2022.
//

import Foundation
import SwiftUI

class APIManager {
    
    @AppStorage("apiBasePath") var apiBasePath: String = defaultApiBasePath
    
    init(
        networkManager: NetworkManager
    ) {
        self.networkManager = networkManager
    }
    
    let networkManager: NetworkManager
}
