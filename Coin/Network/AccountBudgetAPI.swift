//
//  AccountBudgetAPI.swift
//  Coin
//

import Foundation
import ProtoDefinitions
import GRPCCore
import GRPCProtobuf
import GRPCNIOTransportHTTP2
import SwiftProtobuf

extension APIManager {

    func CreateAccountBudget(req: CreateAccountBudgetReq) async throws {

        let accessToken = try await self.networkManager.authManager.getAccessToken()

        let request = AccountBudget_CreateAccountBudgetRequest.with {
            $0.accessToken = accessToken
            $0.id = req.id.data
            $0.accountID = req.accountID.data
            $0.amount = req.amount.doubleValue
            $0.fixedSum = req.fixedSum.doubleValue
            $0.daysOffset = UInt32(req.daysOffset)
            $0.gradualFilling = req.gradualFilling
            $0.effectiveFrom = Google_Protobuf_Timestamp(req.effectiveFrom)
        }

        let response = try await grpcCall("CreateAccountBudget", request: request) {
            try await accountBudgetClient.createAccountBudget($0)
        }

        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }
    }

    func GetAccountBudgets(req: GetAccountBudgetsReq) async throws -> [GetAccountBudgetsRes] {

        let accessToken = try await self.networkManager.authManager.getAccessToken()

        let request = AccountBudget_GetAccountBudgetsRequest.with {
            $0.accessToken = accessToken
            $0.accountGroupIds = req.accountGroupIDs.map { $0.data }
            if let dateFrom = req.dateFrom {
                $0.dateFrom = Google_Protobuf_Timestamp(dateFrom)
            }
            if let dateTo = req.dateTo {
                $0.dateTo = Google_Protobuf_Timestamp(dateTo)
            }
        }

        let response = try await grpcCall("GetAccountBudgets", request: request) {
            try await accountBudgetClient.getAccountBudgets($0)
        }

        guard !response.hasError else {
            throw ErrorModel(humanText: response.error.message, error: response.error.systemMessage)
        }

        return try response.budgets.map { budget in
            GetAccountBudgetsRes(
                id: try budget.id.toUUID(),
                accountID: try budget.accountID.toUUID(),
                amount: Decimal(budget.amount),
                fixedSum: Decimal(budget.fixedSum),
                daysOffset: Int8(budget.daysOffset),
                gradualFilling: budget.gradualFilling,
                effectiveFrom: budget.effectiveFrom.toDate(),
                createdByUserID: try budget.createdByUserID.toUUID(),
                datetimeCreate: budget.datetimeCreate.toDate(),
                accountGroupID: try budget.accountGroupID.toUUID()
            )
        }
    }
}
