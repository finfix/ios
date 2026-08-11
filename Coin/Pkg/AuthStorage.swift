//
//  AuthStorage.swift
//  Coin
//

import Foundation

/// Единый источник правды для isLogin/accessToken/refreshToken — раньше это были
/// независимые @AppStorage(...) с одним и тем же ключом, разбросанные по нескольким файлам
/// (ContentView, LoginView, Profile, DeveloperTools, AuthManager, NetworkManager) и хранившие
/// значения в UserDefaults. Токены — секреты, поэтому переехали в Keychain; @Observable даёт
/// ту же кросс-файловую реактивность, что раньше давал @AppStorage через общий UserDefaults.
@Observable
final class AuthStorage {

    static let shared = AuthStorage()

    private enum Keys {
        static let isLogin = "isLogin"
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }

    var isLogin: Bool {
        didSet {
            if isLogin {
                Keychain.set("true", forKey: Keys.isLogin)
            } else {
                Keychain.delete(Keys.isLogin)
            }
        }
    }

    var accessToken: String? {
        didSet {
            if let accessToken {
                Keychain.set(accessToken, forKey: Keys.accessToken)
            } else {
                Keychain.delete(Keys.accessToken)
            }
        }
    }

    var refreshToken: String? {
        didSet {
            if let refreshToken {
                Keychain.set(refreshToken, forKey: Keys.refreshToken)
            } else {
                Keychain.delete(Keys.refreshToken)
            }
        }
    }

    private init() {
        self.isLogin = Keychain.get(Keys.isLogin) != nil
        self.accessToken = Keychain.get(Keys.accessToken)
        self.refreshToken = Keychain.get(Keys.refreshToken)
    }
}
