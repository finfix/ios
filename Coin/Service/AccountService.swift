//
//  AccountService.swift
//  Coin
//
//  Created by Илья on 18.08.2024.
//

import Foundation
import GRDB

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
        try await taskManager.createTask(
            actionName: .createAccount,
            reqModel: CreateAccountReq(
                id: account.id,
                accountGroupID: account.accountGroup.id,
                accountingInHeader: account.accountingInHeader,
                accountingInCharts: account.accountingInCharts,
                currency: account.currency.code,
                iconID: account.icon.id,
                name: account.name,
                type: account.type.rawValue,
                isParent: account.isParent,
                parentAccountID: account.parentAccountID,
                datetimeCreate: account.datetimeCreate,
                rank: account.rank
            ),
            entityID: account.id,
            dependsOnEntityIDs: [account.accountGroup.id] + (account.parentAccountID.map { [$0] } ?? [])
        )

        if account.budgetAmount != 0 {
            try await createAccountBudget(
                accountID: account.id,
                accountGroupID: account.accountGroup.id,
                amount: account.budgetAmount,
                fixedSum: account.budgetFixedSum,
                daysOffset: account.budgetDaysOffset,
                gradualFilling: account.budgetGradualFilling,
                effectiveFrom: Date.now
            )
        }

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

        let accountsDB = try await repository.getAccounts(
            ids: ids,
            accountGroupIDs: accountGroups?.map(\.id),
            visible: visible,
            accountingInHeader: accountingInHeader,
            types: types,
            currencyCode: currencyCode,
            isParent: isParent,
            name: name
        )

        let budgetsMap = try await effectiveAccountBudgets(accountIDs: accountsDB.map { $0.id! }, on: Date.now)

        return Account.convertFromDBModel(
            accountsDB,
            currenciesMap: currenciesMap,
            accountGroupsMap: accountGroupsMap,
            iconsMap: iconsMap,
            budgetsMap: budgetsMap
        )
    }

    /// Живой список счетов (плоский, без группировки родитель/дети — см. Repository.observeAccounts)
    /// — вызывающая сторона (AccountCirclesViewModel) сама прогоняет через Account.groupAccounts.
    func observeAccounts(
        accountGroups: [AccountGroup]? = nil,
        visible: Bool? = nil,
        accountingInHeader: Bool? = nil
    ) -> AsyncValueObservation<[Account]> {
        repository.observeAccounts(
            accountGroupIDs: accountGroups?.map(\.id),
            visible: visible,
            accountingInHeader: accountingInHeader
        )
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
        
        // Получаем родительский счет — сохраняем оригинальное состояние (oldParentAccount),
        // чтобы ниже явно посчитать диф и отправить на сервер именно то, что реально
        // изменилось у него, а не только у редактируемого счёта.
        let oldParentAccount: Account?
        if let parentAccountID = newAccount.parentAccountID {
            oldParentAccount = try await getAccounts(ids: [parentAccountID]).first
        } else {
            oldParentAccount = nil
        }
        var newParentAccount = oldParentAccount

        // Если значение родительского счета отрицательное, а у дочернего счета положительное
        if let oldParentAccount, !oldParentAccount.accountingInHeader && newAccount.accountingInHeader {
            newParentAccount?.accountingInHeader = true
        }

        // Если значения дочерних счетов положительные, а значение родительского отрицательное
        for (i, childAccount) in newAccount.childrenAccounts.enumerated() {
            if childAccount.accountingInHeader && !newAccount.accountingInHeader {
                newAccount.childrenAccounts[i].accountingInHeader = false
            }
        }

        // Если значение родительского счета отрицательное, а у дочернего счета положительное
        if let oldParentAccount, !oldParentAccount.visible && newAccount.visible {
            newParentAccount?.visible = true
        }

        // Снимок дочерних счетов ДО каскадных изменений видимости — нужен ниже, чтобы отправить
        // на сервер explicit-апдейт именно для тех детей, у кого реально что-то поменялось.
        let oldChildrenAccounts = newAccount.childrenAccounts

        // Если значения родительского счета меняется, то значения дочерних счетов меняются на такое же
        for (i, childAccount) in newAccount.childrenAccounts.enumerated() {
            newAccount.childrenAccounts[i].visible = newAccount.visible
            if !childAccount.visible && childAccount.accountingInHeader {
                newAccount.childrenAccounts[i].accountingInHeader = false
            }
        }

        if let newParentAccount {
            try await repository.updateAccount(newParentAccount)
        }

        for childAccount in newAccount.childrenAccounts {
            try await repository.updateAccount(childAccount)
        }

        try await repository.updateAccount(newAccount)

        let updateReq = UpdateAccountReq(
            id: newAccount.id,
            accountingInHeader: oldAccount.accountingInHeader != newAccount.accountingInHeader ? newAccount.accountingInHeader : nil,
            accountingInCharts: oldAccount.accountingInCharts != newAccount.accountingInCharts ? newAccount.accountingInCharts : nil,
            name: oldAccount.name != newAccount.name ? newAccount.name : nil,
            visible: oldAccount.visible != newAccount.visible ? newAccount.visible : nil,
            currencyCode: oldAccount.currency.code != newAccount.currency.code ? newAccount.currency.code : nil,
            parentAccountID: parentAccountIDToReq,
            iconID: oldAccount.icon != newAccount.icon ? newAccount.icon.id : nil,
            rank: oldAccount.rank != newAccount.rank ? newAccount.rank : nil,
            linkedAccountID: oldAccount.linkedAccountID != newAccount.linkedAccountID ? newAccount.linkedAccountID : nil,
            unlinkAccount: oldAccount.linkedAccountID != nil && newAccount.linkedAccountID == nil
        )
        if updateReq.hasChanges {
            try await taskManager.createTask(
                actionName: .updateAccount,
                reqModel: updateReq,
                entityID: newAccount.id,
                dependsOnEntityIDs: newAccount.parentAccountID.map { [$0] } ?? []
            )
        }

        // Явно отправляем на сервер каскадные изменения родителя (если что-то реально
        // поменялось) — раньше это только писалось в локальную БД, и бэк о таких изменениях
        // не узнавал вовсе.
        if let oldParentAccount, let newParentAccount {
            let parentUpdateReq = UpdateAccountReq(
                id: newParentAccount.id,
                accountingInHeader: oldParentAccount.accountingInHeader != newParentAccount.accountingInHeader ? newParentAccount.accountingInHeader : nil,
                visible: oldParentAccount.visible != newParentAccount.visible ? newParentAccount.visible : nil
            )
            if parentUpdateReq.hasChanges {
                try await taskManager.createTask(
                    actionName: .updateAccount,
                    reqModel: parentUpdateReq,
                    entityID: newParentAccount.id
                )
            }
        }

        // Явно отправляем на сервер каскадные изменения каждого затронутого дочернего счёта.
        for (old, new) in zip(oldChildrenAccounts, newAccount.childrenAccounts) {
            let childUpdateReq = UpdateAccountReq(
                id: new.id,
                accountingInHeader: old.accountingInHeader != new.accountingInHeader ? new.accountingInHeader : nil,
                visible: old.visible != new.visible ? new.visible : nil
            )
            if childUpdateReq.hasChanges {
                try await taskManager.createTask(
                    actionName: .updateAccount,
                    reqModel: childUpdateReq,
                    entityID: new.id
                )
            }
        }

        // Бюджет — отдельная версионируемая сущность: если хоть одно из полей поменялось,
        // создаём НОВУЮ версию (не апдейт), действующую с сегодняшнего дня.
        if oldAccount.budgetAmount != newAccount.budgetAmount ||
            oldAccount.budgetFixedSum != newAccount.budgetFixedSum ||
            oldAccount.budgetDaysOffset != newAccount.budgetDaysOffset ||
            oldAccount.budgetGradualFilling != newAccount.budgetGradualFilling {
            try await createAccountBudget(
                accountID: newAccount.id,
                accountGroupID: newAccount.accountGroup.id,
                amount: newAccount.budgetAmount,
                fixedSum: newAccount.budgetFixedSum,
                daysOffset: newAccount.budgetDaysOffset,
                gradualFilling: newAccount.budgetGradualFilling,
                effectiveFrom: Date.now
            )
        }
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
            var nextRank = index < accounts.count - 1 ? accounts[index + 1].rank : nil

            // Если prevRank >= nextRank (возможно из-за старых rank в неправильном формате),
            // игнорируем nextRank чтобы не передавать невалидный диапазон в Rank.between
            if let p = prevRank, let n = nextRank, p >= n { nextRank = nil }

            let isInOrder = (prevRank.map { $0 < account.rank } ?? true) && (nextRank.map { account.rank < $0 } ?? true)
            guard !isInOrder else { continue }

            let newRank = Rank.between(prevRank, nextRank)
            guard newRank != account.rank else { continue }
            accounts[index].rank = newRank

            var updated = account
            updated.rank = newRank
            try await repository.updateAccount(updated)
            try await taskManager.createTask(
                actionName: .updateAccount,
                reqModel: UpdateAccountReq(id: updated.id, rank: newRank),
                entityID: updated.id
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
        
        try await taskManager.createTask(
            actionName: .deleteAccount,
            reqModel: DeleteAccountReq(id: account.id),
            entityID: account.id
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
    
    // Создаёт родительский балансировочный счет для группы счетов, если его почему-то ещё
    // нет (например, группа была создана раньше, чем появилась логика его автосоздания,
    // либо создание таски на бэк ранее не долетело). Currency у родительского счета не
    // используется при поиске (isParent: true не фильтруется по currencyCode), поэтому
    // берём валюту группы счетов просто как разумное значение по умолчанию.
    private func createParentBalancingAccount(for accountGroup: AccountGroup) async throws -> Account {
        guard let icon = try await getIcons().first else {
            throw ErrorModel(humanText: "Не смогли найти иконку для родительского балансировочного счета")
        }

        let parentBalancingAccount = Account(
            accountingInHeader: false,
            accountingInCharts: false,
            icon: icon,
            name: "Балансировочный",
            remainder: 0,
            type: .balancing,
            visible: true,
            rank: try await nextRank(in: accountGroup),
            isParent: true,
            budgetAmount: 0,
            showingBudgetAmount: 0,
            budgetFixedSum: 0,
            budgetDaysOffset: 0,
            budgetGradualFilling: false,
            parentAccountID: nil,
            accountGroup: accountGroup,
            currency: accountGroup.currency,
            childrenAccounts: []
        )
        try await repository.createAccount(parentBalancingAccount)

        try await taskManager.createTask(
            actionName: .createAccount,
            reqModel: CreateAccountReq(
                id: parentBalancingAccount.id,
                accountGroupID: parentBalancingAccount.accountGroup.id,
                accountingInHeader: parentBalancingAccount.accountingInHeader,
                accountingInCharts: parentBalancingAccount.accountingInCharts,
                currency: parentBalancingAccount.currency.code,
                iconID: parentBalancingAccount.icon.id,
                name: parentBalancingAccount.name,
                type: parentBalancingAccount.type.rawValue,
                isParent: parentBalancingAccount.isParent,
                parentAccountID: parentBalancingAccount.parentAccountID,
                datetimeCreate: parentBalancingAccount.datetimeCreate,
                rank: parentBalancingAccount.rank
            ),
            entityID: parentBalancingAccount.id,
            dependsOnEntityIDs: [parentBalancingAccount.accountGroup.id]
        )

        return parentBalancingAccount
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
        let existingParentBalancingAccount = try await getAccounts(
            accountGroups: [account.accountGroup],
            types: [.balancing],
            isParent: true
        ).first
        let parentBalancingAccount: Account
        if let existingParentBalancingAccount {
            parentBalancingAccount = existingParentBalancingAccount
        } else {
            parentBalancingAccount = try await createParentBalancingAccount(for: account.accountGroup)
        }

        // Создаем дочерний балансировочный счет локально
        let balancingAccount = Account(
            accountingInHeader: true,
            accountingInCharts: true,
            icon: parentBalancingAccount.icon,
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
        )
        try await repository.createAccount(balancingAccount)
        
        // Синхронизируем создание балансировочного счета с сервером
        try await taskManager.createTask(
            actionName: .createAccount,
            reqModel: CreateAccountReq(
                id: balancingAccount.id,
                accountGroupID: balancingAccount.accountGroup.id,
                accountingInHeader: balancingAccount.accountingInHeader,
                accountingInCharts: balancingAccount.accountingInCharts,
                currency: balancingAccount.currency.code,
                iconID: balancingAccount.icon.id,
                name: balancingAccount.name,
                type: balancingAccount.type.rawValue,
                isParent: balancingAccount.isParent,
                parentAccountID: balancingAccount.parentAccountID,
                datetimeCreate: balancingAccount.datetimeCreate,
                rank: balancingAccount.rank
            ),
            entityID: balancingAccount.id,
            dependsOnEntityIDs: [balancingAccount.accountGroup.id, parentBalancingAccount.id]
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
        
        // Сервер требует: accountFrom — всегда балансировочный, accountTo — обычный/долг.
        // Для уменьшения баланса amountTo отрицательный.
        // Для earnings: remainder = -balance, поэтому знак amountTo инвертируется.
        let amountTo: Decimal = account.type == .earnings ? -delta : delta
        
        try await createTransaction(Transaction(
            amountFrom: amountTo,
            amountTo: amountTo,
            type: .balancing,
            accountFrom: balancingAccount,
            accountTo: account,
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
    }
}
