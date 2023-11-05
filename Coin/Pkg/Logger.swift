//
//  Logger.swift
//  Coin
//
//  Created by Илья on 27.10.2023.
//

import Foundation

public func debugLog(_ message: Any, file: String = #file, line: Int = #line, showPath: Bool = true, timeInterval: Date? = nil) {
    
    var log = message
    if let timeInterval {
        log = "\(String(format: "%.3f", -timeInterval.timeIntervalSinceNow))ms \(log)"
    }
    if showPath {
        log = "\(log) \(file.replacingOccurrences(of: "/Users/bonavi/Projects/Coin/App/Coin/", with: "")):\(line)"
    }
    print(log)
}
