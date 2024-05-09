//
//  Hasher.swift
//  Coin
//
//  Created by Илья on 02.05.2024.
//

import Foundation
import CryptoKit

func encryptPassword(password: String, userSalt: String) -> String {
    let generalSalt = "XZ'e9nN=5'qb"
    let saltedPassword = userSalt + password + generalSalt
    let hashedPassword = Insecure.SHA1.hash(data: saltedPassword.data(using: .utf8)!)
    let hashedPasswordString = hashedPassword.compactMap { String(format: "%02x", $0) }.joined()

    return hashedPasswordString
}
