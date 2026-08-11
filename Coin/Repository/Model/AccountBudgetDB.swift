//
//  AccountBudgetDB.swift
//  Coin
//

import Foundation
import GRDB

struct AccountBudgetDB {

    var id: UUID?
    var accountId: UUID
    var amount: Decimal
    var fixedSum: Decimal
    var daysOffset: Int8
    var gradualFilling: Bool
    var effectiveFrom: Date
    var createdByUserID: UUID
    var datetimeCreate: Date
    var accountGroupID: UUID

    init(
        id: UUID,
        accountId: UUID,
        amount: Decimal,
        fixedSum: Decimal,
        daysOffset: Int8,
        gradualFilling: Bool,
        effectiveFrom: Date,
        createdByUserID: UUID,
        datetimeCreate: Date,
        accountGroupID: UUID
    ) {
        self.id = id
        self.accountId = accountId
        self.amount = amount
        self.fixedSum = fixedSum
        self.daysOffset = daysOffset
        self.gradualFilling = gradualFilling
        self.effectiveFrom = effectiveFrom
        self.createdByUserID = createdByUserID
        self.datetimeCreate = datetimeCreate
        self.accountGroupID = accountGroupID
    }

    // Инициализатор из сетевой модели
    init(_ res: GetAccountBudgetsRes) {
        self.id = res.id
        self.accountId = res.accountID
        self.amount = res.amount
        self.fixedSum = res.fixedSum
        self.daysOffset = res.daysOffset
        self.gradualFilling = res.gradualFilling
        self.effectiveFrom = res.effectiveFrom
        self.createdByUserID = res.createdByUserID
        self.datetimeCreate = res.datetimeCreate
        self.accountGroupID = res.accountGroupID
    }

    // Инициализатор из бизнес модели
    init(_ model: AccountBudget) {
        self.id = model.id
        self.accountId = model.accountID
        self.amount = model.amount
        self.fixedSum = model.fixedSum
        self.daysOffset = model.daysOffset
        self.gradualFilling = model.gradualFilling
        self.effectiveFrom = model.effectiveFrom
        self.createdByUserID = model.createdByUserID
        self.datetimeCreate = model.datetimeCreate
        self.accountGroupID = model.accountGroupID
    }

    static func convertFromApiModel(_ budgets: [GetAccountBudgetsRes]) -> [AccountBudgetDB] {
        budgets.map(AccountBudgetDB.init)
    }
}

// MARK: - Persistence
extension AccountBudgetDB: Codable, FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let accountId = Column(CodingKeys.accountId)
        static let amount = Column(CodingKeys.amount)
        static let fixedSum = Column(CodingKeys.fixedSum)
        static let daysOffset = Column(CodingKeys.daysOffset)
        static let gradualFilling = Column(CodingKeys.gradualFilling)
        static let effectiveFrom = Column(CodingKeys.effectiveFrom)
        static let createdByUserID = Column(CodingKeys.createdByUserID)
        static let datetimeCreate = Column(CodingKeys.datetimeCreate)
        static let accountGroupID = Column(CodingKeys.accountGroupID)
    }
}
