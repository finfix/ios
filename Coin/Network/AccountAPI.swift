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

extension Account_GetAccountsRequest {
    init(
        accountingInHeader: Bool?,
        dateFrom: Date?,
        dateTo: Date?,
        type: String?
    ) throws {
        self.init()
        if let accountingInHeader {
            self.accountingInHeader = accountingInHeader
        }
        if let dateFrom {
            self.dateFrom = Google_Protobuf_Timestamp(localFilter: dateFrom)
        }
        if let dateTo {
            self.dateTo = Google_Protobuf_Timestamp(localFilter: dateTo)
        }
        if let type {
            guard let accountType = AccountType(rawValue: type) else {
                throw ErrorModel(humanText: "Неизвестный тип счета: \(type)")
            }
            self.type = try accountType.toProto()
        }
    }
}

extension Account_CreateAccountRequest {
    init(
        id: UUID,
        accountGroupID: UUID,
        accountingInHeader: Bool,
        accountingInCharts: Bool,
        currency: String,
        iconID: UUID,
        name: String,
        type: String,
        isParent: Bool,
        parentAccountID: UUID?,
        datetimeCreate: Date,
        rank: String
    ) throws {
        self.init()
        self.id = id.data
        self.accountGroupID = accountGroupID.data
        self.accountingInHeader = accountingInHeader
        self.accountingInCharts = accountingInCharts
        self.currency = currency
        self.iconID = iconID.data
        self.name = name
        guard let accountType = AccountType(rawValue: type) else {
            throw ErrorModel(humanText: "Неизвестный тип счета: \(type)")
        }
        self.type = try accountType.toProto()
        self.isParent = isParent
        if let parentAccountID {
            self.parentAccountID = parentAccountID.data
        }
        self.datetimeCreate = Google_Protobuf_Timestamp(datetimeCreate)
        self.rank = rank
    }
}

extension Account_UpdateAccountRequest {
    init(
        id: UUID,
        accountingInHeader: Bool?,
        accountingInCharts: Bool?,
        name: String?,
        visible: Bool?,
        currencyCode: String?,
        parentAccountID: UUID?,
        iconID: UUID?,
        rank: String?
    ) {
        self.init()
        self.id = id.data
        if let accountingInHeader {
            self.accountingInHeader = accountingInHeader
        }
        if let accountingInCharts {
            self.accountingInCharts = accountingInCharts
        }
        if let name {
            self.name = name
        }
        if let visible {
            self.visible = visible
        }
        if let currencyCode {
            self.currency = currencyCode
        }
        if let parentAccountID {
            self.parentAccountID = parentAccountID.data
        }
        if let iconID {
            self.iconID = iconID.data
        }
        if let rank {
            self.rank = rank
        }
    }
}

extension Account_DeleteAccountRequest {
    init(id: UUID) {
        self.init()
        self.id = id.data
    }
}

extension APIManager {

    func GetAccounts(req: GetAccountsReq) async throws -> [GetAccountsRes] {

        let request = try Account_GetAccountsRequest(
            accountingInHeader: req.accountingInHeader,
            dateFrom: req.dateFrom,
            dateTo: req.dateTo,
            type: req.type
        )

        let response = try await grpcCall("GetAccounts", request: request) {
            try await accountClient.getAccounts($0)
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

        let request = try Account_CreateAccountRequest(
            id: req.id,
            accountGroupID: req.accountGroupID,
            accountingInHeader: req.accountingInHeader,
            accountingInCharts: req.accountingInCharts,
            currency: req.currency,
            iconID: req.iconID,
            name: req.name,
            type: req.type,
            isParent: req.isParent,
            parentAccountID: req.parentAccountID,
            datetimeCreate: req.datetimeCreate,
            rank: req.rank
        )

        _ = try await grpcCall("CreateAccount", request: request) {
            try await accountClient.createAccount($0)
        }
    }

    func UpdateAccount(req: UpdateAccountReq) async throws {

        let request = Account_UpdateAccountRequest(
            id: req.id,
            accountingInHeader: req.accountingInHeader,
            accountingInCharts: req.accountingInCharts,
            name: req.name,
            visible: req.visible,
            currencyCode: req.currencyCode,
            parentAccountID: req.parentAccountID,
            iconID: req.iconID,
            rank: req.rank
        )

        _ = try await grpcCall("UpdateAccount", request: request) {
            try await accountClient.updateAccount($0)
        }
    }

    func DeleteAccount(req: DeleteAccountReq) async throws {

        let request = Account_DeleteAccountRequest(id: req.id)

        _ = try await grpcCall("DeleteAccount", request: request) {
            try await accountClient.deleteAccount($0)
        }
    }
}
