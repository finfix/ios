//
//  AccountAPI.swift
//  Coin
//
//  Created by Илья on 24.10.2022.
//

import Foundation
import SwiftUI
import ProtoDefinitions
import GRPCCore
import GRPCProtobuf
import GRPCNIOTransportHTTP2
import SwiftProtobuf

extension APIManager {
    
    func GetAccounts(req: GetAccountsReq) async throws -> [GetAccountsRes] {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = try Account_GetAccountsRequest.with {
            $0.accessToken = accessToken
            if let accountingInHeader = req.accountingInHeader {
                $0.accountingInHeader = accountingInHeader
            }
            if let dateFrom = req.dateFrom {
                $0.dateFrom = Google_Protobuf_Timestamp(localFilter: dateFrom)
            }
            if let dateTo = req.dateTo {
                $0.dateTo = Google_Protobuf_Timestamp(localFilter: dateTo)
            }
            if let type = req.type {
                guard let accountType = AccountType(rawValue: type) else {
                    throw ErrorModel(humanText: "Неизвестный тип счета: \(type)")
                }
                $0.type = try accountType.toProto()
            }
        }
        
        let response = try await grpcCall("GetAccounts", request: request) {
            try await accountClient.getAccounts($0)
        }
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
        
        return try response.accounts.map { account in
            GetAccountsRes(
                id: try account.id.toUUID(),
                accountingInHeader: account.accountingInHeader,
                accountingInCharts: account.accountingInCharts,
                iconID: try account.iconID.toUUID(),
                name: account.name,
                remainder: Decimal(account.remainder),
                type: try AccountType(from: account.type),
                visible: account.visible,
                parentAccountID: account.parentAccountID != Data() ? try account.parentAccountID.toUUID() : nil,
                currency: account.currency,
                accountGroupID: try account.accountGroupID.toUUID(),
                rank: account.rank,
                isParent: account.isParent,
                datetimeCreate: account.datetimeCreate.toDate()
            )
        }
    }
    
    func CreateAccount(req: CreateAccountReq) async throws {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = try Account_CreateAccountRequest.with {
            $0.accessToken = accessToken
            $0.id = req.id.data
            $0.accountGroupID = req.accountGroupID.data
            $0.accountingInHeader = req.accountingInHeader
            $0.accountingInCharts = req.accountingInCharts
            $0.currency = req.currency
            $0.iconID = req.iconID.data
            $0.name = req.name
            guard let accountType = AccountType(rawValue: req.type) else {
                throw ErrorModel(humanText: "Неизвестный тип счета: \(req.type)")
            }
            $0.type = try accountType.toProto()
            $0.isParent = req.isParent
            if let parentAccountID = req.parentAccountID {
                $0.parentAccountID = parentAccountID.data
            }
            $0.datetimeCreate = Google_Protobuf_Timestamp(req.datetimeCreate)
            $0.rank = req.rank
        }
        
        let response = try await grpcCall("CreateAccount", request: request) {
            try await accountClient.createAccount($0)
        }
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
    }
    
    func UpdateAccount(req: UpdateAccountReq) async throws {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = Account_UpdateAccountRequest.with {
            $0.accessToken = accessToken
            $0.id = req.id.data
            if let accountingInHeader = req.accountingInHeader {
                $0.accountingInHeader = accountingInHeader
            }
            if let accountingInCharts = req.accountingInCharts {
                $0.accountingInCharts = accountingInCharts
            }
            if let name = req.name {
                $0.name = name
            }
            if let visible = req.visible {
                $0.visible = visible
            }
            if let currencyCode = req.currencyCode {
                $0.currency = currencyCode
            }
            if let parentAccountID = req.parentAccountID {
                $0.parentAccountID = parentAccountID.data
            }
            if let iconID = req.iconID {
                $0.iconID = iconID.data
            }
            if let rank = req.rank {
                $0.rank = rank
            }
        }
        
        let response = try await grpcCall("UpdateAccount", request: request) {
            try await accountClient.updateAccount($0)
        }
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
    }
    
    func DeleteAccount(req: DeleteAccountReq) async throws {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = Account_DeleteAccountRequest.with {
            $0.accessToken = accessToken
            $0.id = req.id.data
        }
        
        let response = try await grpcCall("DeleteAccount", request: request) {
            try await accountClient.deleteAccount($0)
        }
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
    }
}
