//
//  UserDefaults.swift
//  Coin
//
//  Created by Илья on 21.10.2022.
//

import Foundation

class Defaults {
    
    static let defaults = UserDefaults.standard
    
    fileprivate enum Keys: String {
        case accessToken
        case refreshToken
    }
    
    static var accessToken: String? {
        get {
            return defaults.string(forKey: Keys.accessToken.rawValue)
        }
        set {
            defaults.set(newValue, forKey: Keys.accessToken.rawValue)
        }
    }
    
    static var refreshToken: String? {
        get {
            return defaults.string(forKey: Keys.refreshToken.rawValue)
        }
        set {
            defaults.set(newValue, forKey: Keys.refreshToken.rawValue)
        }
    }
    
}
