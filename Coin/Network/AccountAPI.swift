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
//            if let accountGroupID = req.accountGroupID {
//                $0.accountGroupID = accountGroupID.data
//            }
            if let accountingInHeader = req.accountingInHeader {
                $0.accountingInHeader = accountingInHeader
            }
            if let dateFrom = req.dateFrom {
                $0.dateFrom = Google_Protobuf_Timestamp(dateFrom)
            }
            if let dateTo = req.dateTo {
                $0.dateTo = Google_Protobuf_Timestamp(dateTo)
            }
            if let type = req.type {
                guard let accountType = AccountType(rawValue: type) else {
                    throw ErrorModel(humanText: "Неизвестный тип счета: \(type)")
                }
                $0.type = try accountType.toProto()
            }
        }
        
        let response = try await accountClient.getAccounts(request)
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
        
        return try response.accounts.map { account in
            GetAccountsRes(
                id: try account.id.toUUID(),
                accountingInHeader: account.accountingInHeader,
                accountingInCharts: account.accountingInCharts,
                budget: GetAccountBudgetRes(
                    amount: Decimal(account.budget.amount),
                    fixedSum: Decimal(account.budget.fixedSum),
                    gradualFilling: account.budget.gradualFilling,
                    daysOffset: Int8(account.budget.daysOffset)
                ),
                iconID: try account.iconID.toUUID(),
                name: account.name,
                remainder: Decimal(account.remainder),
                type: try AccountType(from: account.type),
                visible: account.visible,
                parentAccountID: account.parentAccountID != Data() ? try account.parentAccountID.toUUID() : nil,
                currency: account.currency,
                accountGroupID: try account.accountGroupID.toUUID(),
                serialNumber: account.serialNumber,
                isParent: account.isParent,
                datetimeCreate: account.datetimeCreate.toDate()
            )
        }
    }
    
    func CreateAccount(req: CreateAccountReq) async throws {
        
        let accessToken = try await self.networkManager.authManager.getAccessToken()
        
        let request = try Account_CreateAccountRequest.with {
            $0.accessToken = accessToken
            $0.accountGroupID = req.accountGroupID.data
            $0.accountingInHeader = req.accountingInHeader
            $0.accountingInCharts = req.accountingInCharts
            $0.budget = Account_AccountBudget.with {
                $0.amount = req.budget.amount.doubleValue
                $0.gradualFilling = req.budget.gradualFilling
                $0.daysOffset = UInt32(req.budget.daysOffset)
                $0.fixedSum = req.budget.fixedSum.doubleValue
            }
            $0.currency = req.currency
            $0.iconID = req.iconID.data
            $0.name = req.name
            if let remainder = req.remainder {
                $0.remainder = remainder.doubleValue
            }
            guard let accountType = AccountType(rawValue: req.type) else {
                throw ErrorModel(humanText: "Неизвестный тип счета: \(req.type)")
            }
            $0.type = try accountType.toProto()
            $0.isParent = req.isParent
            if let parentAccountID = req.parentAccountID {
                $0.parentAccountID = parentAccountID.data
            }
            $0.datetimeCreate = Google_Protobuf_Timestamp(req.datetimeCreate)
        }
        
        let response = try await accountClient.createAccount(request)
        
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
            if let remainder = req.remainder {
                $0.remainder = remainder.doubleValue
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
            if let serialNumber = req.serialNumber {
                $0.serialNumber = serialNumber
            }
            $0.budget = Account_UpdateAccountBudgetRequest.with {
                if let amount = req.budget.amount {
                    $0.amount = amount.doubleValue
                }
                if let fixedSum = req.budget.fixedSum {
                    $0.fixedSum = fixedSum.doubleValue
                }
                if let daysOffset = req.budget.daysOffset {
                    $0.daysOffset = UInt32(daysOffset)
                }
                if let gradualFilling = req.budget.gradualFilling {
                    $0.gradualFilling = gradualFilling
                }
            }
        }
        
        let response = try await accountClient.updateAccount(request)
        
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
        
        let response = try await accountClient.deleteAccount(request)
        
        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
    }
}
