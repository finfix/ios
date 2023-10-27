//
//  Logger.swift
//  Coin
//
//  Created by Илья on 27.10.2023.
//

import Foundation

public func debugLog(_ message: String, file: String = #file, line: Int = #line) {
    print("\(file):\(line) \(message)")
}
