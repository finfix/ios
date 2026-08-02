//
//  AccountService.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import Foundation

extension Service {
    
    // MARK: Create
    func createAccount(_ account: Account) async throws {
        var account = account

        account.remainder = account.remainder.round(factor: 6)
        account.rank = try await nextRank(in: account.accountGroup)

        try validateAccount(account)
                
        try await repository.createAccount(account)
        
        // Добавляем таску создания счета до создания балансировочной транзакции,
        // чтобы на сервере счет существовал раньше транзакции
        taskManager.createTask(
            actionName: .createAccount,
            reqModel: CreateAccountReq(
                id: account.id,
                accountGroupID: account.accountGroup.id,
                accountingInHeader: account.accountingInHeader,
                accountingInCharts: account.accountingInCharts,
                budget: CreateAccountBudgetReq(
                    amount: account.budgetAmount,
                    gradualFilling: account.budgetGradualFilling,
                    daysOffset: account.budgetDaysOffset,
                    fixedSum: account.budgetFixedSum
                ),
                currency: account.currency.code,
                iconID: account.icon.id,
                name: account.name,
                type: account.type.rawValue,
                isParent: account.isParent,
                parentAccountID: account.parentAccountID,
                datetimeCreate: account.datetimeCreate,
                rank: account.rank
            )
        )

        if account.remainder != 0 {
            let balancingAccount = try await findOrCreateBalancingAccount(for: account)
            try await createBalancingTransaction(
                account: account,
                balancingAccount: balancingAccount,
                delta: account.remainder
            )
        }
    }
    
    // MARK: Read
    func getAccounts(
        ids: [UUID]? = nil,
        accountGroups: [AccountGroup]? = nil,
        visible: Bool? = nil,
        accountingInHeader: Bool? = nil,
        types: [AccountType]? = nil,
        currencyCode: String? = nil,
        isParent: Bool? = nil,
        name: String? = nil
    ) async throws -> [Account] {
        let iconsMap = Icon.convertToMap(Icon.convertFromDBModel(try await repository.getIcons()))
        let currenciesMap = Currency.convertToMap(Currency.convertFromDBModel(try await repository.getCurrencies()))
        let accountGroupsMap = AccountGroup.convertToMap(AccountGroup.convertFromDBModel(try await repository.getAccountGroups(), currenciesMap: currenciesMap))
        return Account.convertFromDBModel(try await repository.getAccounts(
            ids: ids,
            accountGroupIDs: accountGroups?.map(\.id),
            visible: visible,
            accountingInHeader: accountingInHeader,
            types: types,
            currencyCode: currencyCode,
            isParent: isParent,
            name: name
        ), currenciesMap: currenciesMap, accountGroupsMap: accountGroupsMap, iconsMap: iconsMap)
    }
    
    // MARK: Update
    func updateAccount(newAccount: Account, oldAccount: Account) async throws {
        var newAccount = newAccount
        
        newAccount.remainder = newAccount.remainder.round(factor: 6)
        
        // Получаем корректное значение parentAccountID для сервера
        var parentAccountIDToReq: UUID? = nil
        if oldAccount.parentAccountID != newAccount.parentAccountID {
            if newAccount.parentAccountID == nil {
                parentAccountIDToReq = UUID(uuid: UUID_NULL)
            } else {
                parentAccountIDToReq = newAccount.parentAccountID
            }
        }
        
        try validateAccount(newAccount)
                
        // Если изменился баланс счета — явно создаем балансировочную транзакцию
        if oldAccount.remainder != newAccount.remainder {
            let balancingAccount = try await findOrCreateBalancingAccount(for: newAccount)
            try await createBalancingTransaction(
                account: newAccount,
                balancingAccount: balancingAccount,
                delta: newAccount.remainder - oldAccount.remainder
            )
        }
        
        // Получаем родительский счет
        var parentAccount: Account?
        if let parentAccountID = newAccount.parentAccountID {
            parentAccount = try await getAccounts(ids: [parentAccountID]).first
        }
        
        // Если значение родительского счета отрицательное, а у дочернего счета положительное
        if parentAccount != nil && !parentAccount!.accountingInHeader && newAccount.accountingInHeader {
            parentAccount!.accountingInHeader = true
        }
        
        // Если значения дочерних счетов положительные, а значение родительского отрицательное
        for (i, childAccount) in newAccount.childrenAccounts.enumerated() {
            if childAccount.accountingInHeader && !newAccount.accountingInHeader {
                newAccount.childrenAccounts[i].accountingInHeader = false
            }
        }
        
        // Если значение родительского счета отрицательное, а у дочернего счета положительное
        if parentAccount != nil && !parentAccount!.visible && newAccount.visible {
            parentAccount!.visible = true
        }
        
        // Если значения родительского счета меняется, то значения дочерних счетов меняются на такое же
        for (i, childAccount) in newAccount.childrenAccounts.enumerated() {
            newAccount.childrenAccounts[i].visible = newAccount.visible
            if !childAccount.visible && childAccount.accountingInHeader {
                newAccount.childrenAccounts[i].accountingInHeader = false
            }
        }
        
        if let parentAccount = parentAccount {
            try await repository.updateAccount(parentAccount)
        }

        for childAccount in newAccount.childrenAccounts {
            try await repository.updateAccount(childAccount)
        }
        
        try await repository.updateAccount(newAccount)
        
        taskManager.createTask(
            actionName: .updateAccount,
            reqModel: UpdateAccountReq(
                id: newAccount.id,
                accountingInHeader: oldAccount.accountingInHeader != newAccount.accountingInHeader ? newAccount.accountingInHeader : nil,
                accountingInCharts: oldAccount.accountingInCharts != newAccount.accountingInCharts ? newAccount.accountingInCharts : nil,
                name: oldAccount.name != newAccount.name ? newAccount.name : nil,
                visible: oldAccount.visible != newAccount.visible ? newAccount.visible : nil,
                currencyCode: oldAccount.currency.code != newAccount.currency.code ? newAccount.currency.code : nil,
                parentAccountID: parentAccountIDToReq,
                iconID: oldAccount.icon != newAccount.icon ? newAccount.icon.id : nil,
                rank: oldAccount.rank != newAccount.rank ? newAccount.rank : nil,
                budget: UpdateBudgetReq(
                    amount: oldAccount.budgetAmount != newAccount.budgetAmount ? newAccount.budgetAmount : nil,
                    fixedSum: oldAccount.budgetFixedSum != newAccount.budgetFixedSum ? newAccount.budgetFixedSum : nil,
                    daysOffset: oldAccount.budgetDaysOffset != newAccount.budgetDaysOffset ? newAccount.budgetDaysOffset : nil,
                    gradualFilling: oldAccount.budgetGradualFilling != newAccount.budgetGradualFilling ? newAccount.budgetGradualFilling : nil)
            )
        )
    }
    
    // MARK: Reorder
    // Пересчитывает rank только у счетов, чьё положение в новом порядке не согласуется
    // с их текущим rank. Каждое изменение — независимая задача на один счет, без
    // затрагивания соседей (в отличие от старой схемы со сдвигом serialNumber)
    func reorderAccounts(_ accounts: [Account]) async throws {
        var accounts = accounts
        for index in accounts.indices {
            let account = accounts[index]
            let prevRank = index > 0 ? accounts[index - 1].rank : nil
            let nextRank = index < accounts.count - 1 ? accounts[index + 1].rank : nil

            let isInOrder = (prevRank.map { $0 < account.rank } ?? true) && (nextRank.map { account.rank < $0 } ?? true)
            guard !isInOrder else { continue }

            let newRank = Rank.between(prevRank, nextRank)
            accounts[index].rank = newRank

            var updated = account
            updated.rank = newRank
            try await repository.updateAccount(updated)
            taskManager.createTask(
                actionName: .updateAccount,
                reqModel: UpdateAccountReq(id: updated.id, rank: newRank, budget: UpdateBudgetReq())
            )
        }
    }

    // MARK: Delete
    func deleteAccount(_ account: Account) async throws {
        
        
        // Если у счета есть дочерние счета
        for childAccount in account.childrenAccounts {
            var childAccount = childAccount
            childAccount.parentAccountID = nil
            try await repository.updateAccount(childAccount)
        }
        
        // Удаляем счет
        try await repository.deleteAccount(account)
        
        taskManager.createTask(
            actionName: .deleteAccount,
            reqModel: DeleteAccountReq(id: account.id)
        )
    }
    
    func recalculateAccountBalances(
        accounts: [Account] = [],
        accountGroups: [AccountGroup] = [],
        accountTypes: [AccountType] = []
    ) async throws {
        var balances: [UUID: Decimal] = [:]
                
        let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let dateFrom = Calendar.current.date(from: DateComponents(year: today.year, month: today.month, day: 1))
        let dateTo = Calendar.current.date(from: DateComponents(year: today.year, month: today.month! + 1, day: 1))
        
        let expensesAndEarningsBalances = try await repository.getBalances(
            accountIDs: accounts.filter { $0.type == .expense || $0.type == .earnings || $0.type == .balancing }.map(\.id),
            dateFrom: dateFrom,
            dateTo: dateTo,
            accountTypes: accountTypes.filter { $0 == .expense || $0 == .earnings || $0 == .balancing },
            accountGroupIDs: accountGroups.map(\.id)
        )
        balances = balances.merging(expensesAndEarningsBalances) { (current, _) in current }

        let regularAndDebtBalances = try await repository.getBalances(
            accountIDs: accounts.filter { $0.type == .regular || $0.type == .debt }.map(\.id),
            accountTypes: accountTypes.filter { $0 == .regular || $0 == .debt },
            accountGroupIDs: accountGroups.map(\.id)
        )
        balances = balances.merging(regularAndDebtBalances) { (current, _) in current }
        
        for (accountID, balance) in balances {
            try await repository.updateBalance(id: accountID, newBalance: balance.round(factor: 7))
        }
    }
    
    // Ищет балансировочный дочерний счет нужной валюты; если не найден — создаёт его
    // и добавляет таску синхронизации с сервером
    private func findOrCreateBalancingAccount(for account: Account) async throws -> Account {
        if let existing = try await getAccounts(
            accountGroups: [account.accountGroup],
            types: [.balancing],
            currencyCode: account.currency.code,
            isParent: false
        ).first {
            return existing
        }
        
        // Дочерний балансировочный счет не найден — ищем родительский
        guard let parentBalancingAccount = try await getAccounts(
            accountGroups: [account.accountGroup],
            types: [.balancing],
            isParent: true
        ).first else {
            throw ErrorModel(humanText: "Не смогли найти родительский балансировочный счет для группы счетов \(account.accountGroup.id)")
        }
        
        // Создаем дочерний балансировочный счет локально
        let balancingAccount = try await repository.createAccountAndReturn(Account(
            accountingInHeader: true,
            accountingInCharts: true,
            icon: Icon(id: UUID(uuid: UUID_NULL)),
            name: "Балансировочный",
            remainder: 0,
            type: .balancing,
            visible: true,
            rank: try await nextRank(in: account.accountGroup),
            isParent: false,
            budgetAmount: 0,
            showingBudgetAmount: 0,
            budgetFixedSum: 0,
            budgetDaysOffset: 0,
            budgetGradualFilling: false,
            parentAccountID: parentBalancingAccount.id,
            accountGroup: account.accountGroup,
            currency: account.currency,
            childrenAccounts: []
        ))
        
        // Синхронизируем создание балансировочного счета с сервером
        taskManager.createTask(
            actionName: .createAccount,
            reqModel: CreateAccountReq(
                id: balancingAccount.id,
                accountGroupID: balancingAccount.accountGroup.id,
                accountingInHeader: balancingAccount.accountingInHeader,
                accountingInCharts: balancingAccount.accountingInCharts,
                budget: CreateAccountBudgetReq(
                    amount: 0,
                    gradualFilling: false,
                    daysOffset: 0,
                    fixedSum: 0
                ),
                currency: balancingAccount.currency.code,
                iconID: balancingAccount.icon.id,
                name: balancingAccount.name,
                type: balancingAccount.type.rawValue,
                isParent: balancingAccount.isParent,
                parentAccountID: balancingAccount.parentAccountID,
                datetimeCreate: balancingAccount.datetimeCreate,
                rank: balancingAccount.rank
            )
        )
        
        return balancingAccount
    }
    
    // Создает балансировочную транзакцию на delta между балансировочным счетом и целевым.
    // Для earnings: balance = -remainder, поэтому направление транзакции обратное.
    private func createBalancingTransaction(
        account: Account,
        balancingAccount: Account,
        delta: Decimal
    ) async throws {
        guard delta != 0 else { return }
        
        let amount = abs(delta)
        
        // Определяем, нужно ли увеличить balance счета
        let shouldIncreaseBalance: Bool
        if account.type == .earnings {
            // Для earnings: remainder = -balance, рост remainder уменьшает balance
            shouldIncreaseBalance = delta < 0
        } else {
            shouldIncreaseBalance = delta > 0
        }
        
        let accountFrom: Account
        let accountTo: Account
        if shouldIncreaseBalance {
            // Увеличиваем balance: balancingAccount -> account
            accountFrom = balancingAccount
            accountTo = account
        } else {
            // Уменьшаем balance: account -> balancingAccount
            accountFrom = account
            accountTo = balancingAccount
        }
        
        try await createTransaction(Transaction(
            amountFrom: amount,
            amountTo: amount,
            type: .balancing,
            accountFrom: accountFrom,
            accountTo: accountTo,
            accountGroupID: account.accountGroup.id
        ))
    }
    
    // Вычисляет rank для нового счета — сразу после последнего существующего счета группы
    private func nextRank(in accountGroup: AccountGroup) async throws -> String {
        let lastRank = try await getAccounts(accountGroups: [accountGroup]).map(\.rank).max()
        return Rank.between(lastRank, nil)
    }

    private func validateAccount(_ account: Account) throws {
        guard account.name != "" else {
            throw ErrorModel(humanText: "Имя счета не может быть пустым")
        }
        
        guard account.budgetAmount >= 0 else {
            throw ErrorModel(humanText: "Бюджет не может быть отрицательным")
        }
        
        guard account.budgetFixedSum >= 0 else {
            throw ErrorModel(humanText: "Фиксированная сумма бюджета не может быть отрицательной")
        }
        
        guard account.budgetDaysOffset >= 0 else {
            throw ErrorModel(humanText: "Количество дней отступа не может быть отрицательным")
        }
        
        guard account.budgetFixedSum <= account.budgetAmount else {
            throw ErrorModel(humanText: "Фиксированная сумма бюджета не может быть больше бюджета")
        }
        
        guard account.budgetDaysOffset < Calendar.current.range(of: .day, in: .month, for: Date())!.count else {
            throw ErrorModel(humanText: "Количество дней отступа не может быть больше или равно количеству дней в месяце")
        }
    }
}
