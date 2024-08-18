//
//  JWTChecker.swift
//  Coin
//
//  Created by Илья on 10.07.2024.
//

import Foundation

enum JWTError: LocalizedError {
    case invalidToken
    case unableDecodeToken
    case tokenExpired(TimeInterval)
}

func checkJWT(_ token: String) throws {
    
    struct JWTPayload: Decodable {
        let exp: Int
    }
    
    let tokenParts = token.components(separatedBy: ".")
    guard tokenParts.count == 3 else {
        throw JWTError.invalidToken
    }
    
    let payloadSegment = String(tokenParts[1])
    
    // Base64 URL декодирование (замена URL-совместимых символов)
    var base64String = payloadSegment
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    
    // Добавляем недостающие "=" в конец строки
    while base64String.count % 4 != 0 {
        base64String += "="
    }
    
    guard let payload = Data(base64Encoded: base64String) else {
        throw JWTError.unableDecodeToken
    }
    
    let decodedPayload = try JSONDecoder().decode(JWTPayload.self, from: payload)
    
    let tokenExpiryDatetime = Date(timeIntervalSince1970: TimeInterval(decodedPayload.exp))
    
    guard tokenExpiryDatetime.adding(.second, value: -5) > Date.now else {
        throw JWTError.tokenExpired(Date.now - tokenExpiryDatetime)
    }
}
