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

extension AccountBudget_CreateAccountBudgetRequest {
    init(
        id: UUID,
        accountID: UUID,
        amount: Decimal,
        fixedSum: Decimal,
        daysOffset: Int8,
        gradualFilling: Bool,
        effectiveFrom: Date
    ) {
        self.init()
        self.id = id.data
        self.accountID = accountID.data
        self.amount = amount.doubleValue
        self.fixedSum = fixedSum.doubleValue
        self.daysOffset = UInt32(daysOffset)
        self.gradualFilling = gradualFilling
        self.effectiveFrom = Google_Protobuf_Timestamp(effectiveFrom)
    }
}

extension AccountBudget_GetAccountBudgetsRequest {
    init(
        accountGroupIDs: [UUID],
        dateFrom: Date?,
        dateTo: Date?
    ) {
        self.init()
        self.accountGroupIds = accountGroupIDs.map { $0.data }
        if let dateFrom {
            self.dateFrom = Google_Protobuf_Timestamp(dateFrom)
        }
        if let dateTo {
            self.dateTo = Google_Protobuf_Timestamp(dateTo)
        }
    }
}

extension APIManager {

    func CreateAccountBudget(req: CreateAccountBudgetReq) async throws {

        let request = AccountBudget_CreateAccountBudgetRequest(
            id: req.id,
            accountID: req.accountID,
            amount: req.amount,
            fixedSum: req.fixedSum,
            daysOffset: req.daysOffset,
            gradualFilling: req.gradualFilling,
            effectiveFrom: req.effectiveFrom
        )

        _ = try await grpcCall("CreateAccountBudget", request: request) {
            try await accountBudgetClient.createAccountBudget($0)
        }
    }

    func GetAccountBudgets(req: GetAccountBudgetsReq) async throws -> [GetAccountBudgetsRes] {

        let request = AccountBudget_GetAccountBudgetsRequest(
            accountGroupIDs: req.accountGroupIDs,
            dateFrom: req.dateFrom,
            dateTo: req.dateTo
        )

        let response = try await grpcCall("GetAccountBudgets", request: request) {
            try await accountBudgetClient.getAccountBudgets($0)
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
