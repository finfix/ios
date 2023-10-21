//
//  AccountModels.swift
//  Coin
//
//  Created by Илья on 31.05.2023.
//

import Foundation

struct GetAccountsRequest: Encodable {
    var accountGroupID: UInt32?
    var accounting: Bool?
    var period: String?
    var type: String?
    
    var queryParameters:[String: Any] {
        get {
            return ["period": "month"] as [String : Any]
        }
    }
}

struct CreateAccountReq: Encodable {
    var accountGroupID: UInt32
    var accounting: Bool
    var budget: Double?
    var currency: String
    var iconID: UInt32
    var name: String
    var remainder: Double?
    var type: String
}

struct UpdateAccountReq: Encodable {
    var id: UInt32
    var accounting: Bool?
    var budget: Double?
//    var iconID: UInt32?
    var name: String?
    var remainder: Double?
    var visible: Bool?
}
