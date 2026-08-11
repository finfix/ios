//
//  AccountBudget.swift
//  Coin
//

import Foundation

/// Версия бюджета счёта, действующая с определённой даты (effectiveFrom). Изменение бюджета
/// всегда создаёт новую версию — старые не редактируются и не удаляются.
struct AccountBudget: Identifiable, Hashable {
    var id: UUID
    var accountID: UUID
    var amount: Decimal
    var fixedSum: Decimal
    var daysOffset: Int8
    var gradualFilling: Bool
    var effectiveFrom: Date
    var createdByUserID: UUID
    var datetimeCreate: Date
    var accountGroupID: UUID

    init(
        id: UUID = UUID(),
        accountID: UUID,
        amount: Decimal,
        fixedSum: Decimal,
        daysOffset: Int8,
        gradualFilling: Bool,
        effectiveFrom: Date,
        createdByUserID: UUID = UUID(),
        datetimeCreate: Date = Date(),
        accountGroupID: UUID
    ) {
        self.id = id
        self.accountID = accountID
        self.amount = amount
        self.fixedSum = fixedSum
        self.daysOffset = daysOffset
        self.gradualFilling = gradualFilling
        self.effectiveFrom = effectiveFrom
        self.createdByUserID = createdByUserID
        self.datetimeCreate = datetimeCreate
        self.accountGroupID = accountGroupID
    }

    init(_ dbModel: AccountBudgetDB) {
        self.id = dbModel.id!
        self.accountID = dbModel.accountId
        self.amount = dbModel.amount
        self.fixedSum = dbModel.fixedSum
        self.daysOffset = dbModel.daysOffset
        self.gradualFilling = dbModel.gradualFilling
        self.effectiveFrom = dbModel.effectiveFrom
        self.createdByUserID = dbModel.createdByUserID
        self.datetimeCreate = dbModel.datetimeCreate
        self.accountGroupID = dbModel.accountGroupID
    }

    static func convertFromDBModel(_ dbModels: [AccountBudgetDB]) -> [AccountBudget] {
        dbModels.map(AccountBudget.init)
    }
}
