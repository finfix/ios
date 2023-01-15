//
//  Order.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import Foundation

/// Эта модель соответствует идентифицируемым и декодируемым протоколам. Идентифицируемый означает, что каждый элемент имеет уникальный идентификатор. Декодируемый означает, что его можно декодировать - например, мы можем преобразовать объект JSON в эту модель данных.

struct Account: Decodable, Identifiable, Hashable {
    var accountGroupID: Int
    var accounting: Bool
    var budget: Double?
    var currencySignatura: String
    var iconID: Int
    var id: Int
    var name: String
    var remainder: Double
    var typeSignatura: String
    var userID: Int
    var visible: Bool
}
