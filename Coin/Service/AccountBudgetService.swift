//
//  AccountBudgetService.swift
//  Coin
//

import Foundation

extension Service {

    // MARK: Create
    // Изменение бюджета всегда создаёт новую версию — старые версии не редактируются и не
    // удаляются (ни локально, ни на сервере).
    func createAccountBudget(
        accountID: UUID,
        accountGroupID: UUID,
        amount: Decimal,
        fixedSum: Decimal,
        daysOffset: Int8,
        gradualFilling: Bool,
        effectiveFrom: Date
    ) async throws {
        try validateAccountBudget(amount: amount, fixedSum: fixedSum, daysOffset: daysOffset)

        let budget = AccountBudget(
            accountID: accountID,
            amount: amount,
            fixedSum: fixedSum,
            daysOffset: daysOffset,
            gradualFilling: gradualFilling,
            effectiveFrom: effectiveFrom,
            accountGroupID: accountGroupID
        )

        try await repository.createAccountBudget(budget)

        taskManager.createTask(
            actionName: .createAccountBudget,
            reqModel: CreateAccountBudgetReq(
                id: budget.id,
                accountID: budget.accountID,
                amount: budget.amount,
                fixedSum: budget.fixedSum,
                daysOffset: budget.daysOffset,
                gradualFilling: budget.gradualFilling,
                effectiveFrom: budget.effectiveFrom
            )
        )
    }

    // MARK: Read
    /// Действующая на дату `date` версия бюджета каждого из `accountIDs` (по одной на счёт,
    /// либо отсутствует, если версий ещё не было) — самая свежая версия с
    /// effectiveFrom <= date среди уже засинканных локально.
    func effectiveAccountBudgets(accountIDs: [UUID], on date: Date) async throws -> [UUID: AccountBudget] {
        let budgets = AccountBudget.convertFromDBModel(try await repository.getAccountBudgets(accountIDs: accountIDs))
        var result: [UUID: AccountBudget] = [:]
        for budget in budgets where budget.effectiveFrom <= date {
            // budgets уже отсортированы по effectiveFrom по убыванию (Repository.getAccountBudgets),
            // поэтому первое подходящее значение на счёт — самое свежее.
            if result[budget.accountID] == nil {
                result[budget.accountID] = budget
            }
        }
        return result
    }

    private func validateAccountBudget(amount: Decimal, fixedSum: Decimal, daysOffset: Int8) throws {
        guard amount >= 0 else {
            throw ErrorModel(humanText: "Бюджет не может быть отрицательным")
        }

        guard fixedSum >= 0 else {
            throw ErrorModel(humanText: "Фиксированная сумма бюджета не может быть отрицательной")
        }

        guard fixedSum <= amount else {
            throw ErrorModel(humanText: "Фиксированная сумма бюджета не может быть больше бюджета")
        }

        guard daysOffset >= 0 else {
            throw ErrorModel(humanText: "Количество дней отступа не может быть отрицательным")
        }

        guard daysOffset < Calendar.current.range(of: .day, in: .month, for: Date())!.count else {
            throw ErrorModel(humanText: "Количество дней отступа не может быть больше или равно количеству дней в месяце")
        }
    }
}
