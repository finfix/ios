//
//  Transaction.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import Foundation

/// Эта модель соответствует идентифицируемым и декодируемым протоколам. Идентифицируемый означает, что каждый элемент имеет уникальный идентификатор. Декодируемый означает, что его можно декодировать - например, мы можем преобразовать объект JSON в эту модель данных.

struct Transaction: Decodable {
    var accountFromID: Int
    var accountToID: Int
    var accounting: Bool
    var amountFrom: Double
    var amountTo: Double
    var dateTransaction: Date
    var id: Int
    var isExecuted: Bool
    var note: String?
    var typeSignatura: String
    var tagName: [Tag]?

    struct Tag: Decodable {
        var id: Int
        var tagID: Int
        var transactionID: Int
    }
}

struct ModelError: Decodable {
    var humanTextError: String
    var developerTextError: String
    var context: String?
}

