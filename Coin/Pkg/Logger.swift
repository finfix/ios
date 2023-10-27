//
//  Logger.swift
//  Coin
//
//  Created by Илья on 27.10.2023.
//

import Foundation

public func debugLog(_ message: Any, file: String = #file, line: Int = #line, showPath: Bool = true) {
    if showPath {
        print("\(file):\(line) \(message)")
    } else {
        print(message)
    }
}
