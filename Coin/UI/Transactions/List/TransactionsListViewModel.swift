//
//  TransactionsListViewModel.swift
//  Coin
//

import Foundation
import Factory

struct TransactionItem: Identifiable {
    let id: UUID
    let index: Int
    let transaction: TransactionListRowData
    let isNewSection: Bool
    // Заполняется только у последней транзакции дня — суммарный расход за день,
    // сконвертированный в валюту группы счетов.
    let isLastOfDay: Bool
    let dailyExpenseTotal: Decimal?
    let dailyExpenseCurrency: Currency?
}

@Observable
class TransactionsListViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service

    private(set) var transactionItems: [TransactionItem] = []

    // Только облегчённые TransactionListRowData копятся по мере подгрузки страниц — полные
    // Transaction (с вложенными Account) в памяти не держим, они достаются из БД по требованию
    // (см. fetchFullTransaction). Строки только растут (по мере скролла вниз и прыжков по
    // календарю) и сбрасываются лишь при смене фильтров — обратно наверх можно вернуться
    // обычным скроллом, ничего не подгружая заново.
    @ObservationIgnored private var rows: [TransactionListRowData] = []

    @ObservationIgnored private var currentFilters = TransactionFilters(accountGroups: [])
    private let pageSize = 100

    private(set) var hasMorePages = true
    private(set) var isLoadingNextPage = false

    /// Все дни, у которых есть транзакции (в рамках фильтров), в хронологическом порядке
    /// (по возрастанию) — используется горизонтальным календарём. Грузится отдельным лёгким
    /// запросом (см. Repository.getTransactionDays), поэтому показывает сразу всю историю, а не
    /// только уже подгруженный пагинацией хвост.
    private(set) var transactionDays: [Date] = []

    var user: User = User()

    private struct AccountFilterIDs {
        let accountIDs: [UUID]
        let excludedAccountIDs: [UUID]
    }

    private func accountFilterIDs(_ filters: TransactionFilters) -> AccountFilterIDs {
        var accountIDs: [UUID] = []
        for account in filters.accounts {
            accountIDs.append(account.id)
            for childAccount in account.childrenAccounts {
                accountIDs.append(childAccount.id)
            }
        }

        var excludedAccountIDs: [UUID] = []
        for account in filters.excludedAccounts {
            excludedAccountIDs.append(account.id)
            for childAccount in account.childrenAccounts {
                excludedAccountIDs.append(childAccount.id)
            }
        }

        return AccountFilterIDs(accountIDs: accountIDs, excludedAccountIDs: excludedAccountIDs)
    }

    /// Полный Transaction (с вложенными Account) достаётся из БД по требованию — только в
    /// момент тапа по строке, а не хранится в памяти для всего списка (см.
    /// TransactionListRowData — именно он используется при рендере списка).
    func fetchFullTransaction(id: UUID) async throws -> Transaction? {
        try await service.getTransactions(ids: [id]).first
    }

    @MainActor
    func load(filters: TransactionFilters) async throws {
        currentFilters = filters
        hasMorePages = true
        rows = []
        transactionItems = []

        let ids = accountFilterIDs(filters)

        async let days = service.getTransactionDays(
            dateFrom: filters.dateFrom,
            dateTo: filters.dateTo,
            searchText: filters.searchText,
            accountIDs: ids.accountIDs,
            excludedAccountIDs: ids.excludedAccountIDs,
            transactionTypes: filters.transactionTypes,
            currencies: filters.currencies,
            tagIDs: filters.tags.map(\.id),
            accountGroupIDs: filters.accountGroups.map(\.id)
        )

        async let firstPage: () = loadPage(before: nil)

        (transactionDays, _) = try await (days, firstPage)
    }

    /// "Умная" пагинация: следующая страница подгружается только когда пользователь долистал
    /// до последней уже отрисованной строки ("до дна"), а не заранее.
    @MainActor
    func loadMoreIfNeeded(currentItem: TransactionItem) async throws {
        guard transactionItems.last?.id == currentItem.id else { return }
        try await loadPage(before: rows.last?.dateTransaction)
    }

    /// Прыжок по календарю на давнюю дату: список остаётся последовательным, без разрывов —
    /// просто продолжаем обычную подгрузку "по дну" (те же страницы, что и при скролле) до тех
    /// пор, пока запрошенный день не окажется среди загруженных. Если пользователь прыгает на
    /// самую первую транзакцию — значит подгрузится вся история целиком, это осознанный
    /// компромисс в пользу простоты и отсутствия "дыр" в списке.
    @MainActor
    func jumpTo(day: Date) async throws -> UUID? {
        while !rows.contains(where: { $0.dateTransaction == day }) && hasMorePages {
            try await loadPage(before: rows.last?.dateTransaction)
        }
        return rows.first(where: { $0.dateTransaction == day })?.id
    }

    /// Загружает страницу транзакций строго ДО даты `before` (не включая её — она уже есть
    /// среди rows от предыдущей страницы), либо, если `includingCursorDay`, включительно (для
    /// прыжка по календарю, где before — это сам целевой день).
    @MainActor
    private func loadPage(before: Date?, includingCursorDay: Bool = false) async throws {
        guard !isLoadingNextPage, hasMorePages else { return }
        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        let ids = accountFilterIDs(currentFilters)

        var cursor = before
        if let before, !includingCursorDay {
            cursor = Calendar.current.date(byAdding: .day, value: -1, to: before)
        }

        // Курсор — чисто внутренний механизм пагинации, юзер о нём не знает и явно заданный
        // им фильтр dateTo (если есть) не должен подменяться им, а только дополнительно
        // сужаться: эффективная верхняя граница — это пересечение курсора и фильтра, что бы
        // из них ни оказалось меньше.
        let effectiveDateTo: Date?
        switch (cursor, currentFilters.dateTo) {
        case (nil, nil): effectiveDateTo = nil
        case (let c?, nil): effectiveDateTo = c
        case (nil, let filterDateTo?): effectiveDateTo = filterDateTo
        case (let c?, let filterDateTo?): effectiveDateTo = min(c, filterDateTo)
        }

        // Курсор ушёл за нижнюю границу фильтра — дальше грузить нечего.
        if let effectiveDateTo, let filterDateFrom = currentFilters.dateFrom, effectiveDateTo < filterDateFrom {
            hasMorePages = false
            return
        }

        let page = try await service.getTransactions(
            limit: pageSize,
            dateFrom: currentFilters.dateFrom,
            dateTo: effectiveDateTo,
            searchText: currentFilters.searchText,
            accountIDs: ids.accountIDs,
            excludedAccountIDs: ids.excludedAccountIDs,
            transactionTypes: currentFilters.transactionTypes,
            currencies: currentFilters.currencies,
            tagIDs: currentFilters.tags.map(\.id),
            accountGroupIDs: currentFilters.accountGroups.map(\.id)
        )

        self.user = try await service.getUsers()[0]

        hasMorePages = page.count == pageSize
        rows.append(contentsOf: page.map(TransactionListRowData.init))
        rebuildTransactionItems()
    }

    /// Пересчитывает isNewSection/isLastOfDay/dailyExpenseTotal по уже накопленным rows.
    /// Дёшево (это лёгкие структуры, не полные Transaction), поэтому пересчёт всего массива
    /// при каждой подгруженной странице не проблема — а без него день, разрезанный границей
    /// страницы, временно получил бы неполную сумму расхода.
    private func rebuildTransactionItems() {
        let targetCurrency = currentFilters.accountGroups.count == 1 ? currentFilters.accountGroups[0].currency : user.defaultCurrency

        transactionItems = rows.enumerated().map { index, row in
            var isNewSection = true
            if index > 0 {
                isNewSection = rows[index].dateTransaction != rows[index - 1].dateTransaction
            }

            var isLastOfDay = true
            if index < rows.count - 1 {
                isLastOfDay = rows[index].dateTransaction != rows[index + 1].dateTransaction
            }

            var dailyExpenseTotal: Decimal?
            if isLastOfDay {
                var total: Decimal = 0
                for other in rows where other.dateTransaction == row.dateTransaction && other.type == .consumption {
                    let currencyRate = targetCurrency.rate / other.accountToCurrency.rate
                    total += other.amountTo * currencyRate
                }
                if total != 0 {
                    dailyExpenseTotal = total
                }
            }

            return TransactionItem(
                id: row.id,
                index: index,
                transaction: row,
                isNewSection: isNewSection,
                isLastOfDay: isLastOfDay,
                dailyExpenseTotal: dailyExpenseTotal,
                dailyExpenseCurrency: dailyExpenseTotal != nil ? targetCurrency : nil
            )
        }
    }

    func deleteTransaction(_ transaction: Transaction) async throws {
        guard rows.contains(where: { $0.id == transaction.id }) else {
            throw ErrorModel(humanText: "Не смогли найти позицию транзакции №\(transaction.id) в массиве")
        }
        rows.removeAll { $0.id == transaction.id }
        try await service.deleteTransaction(transaction)
        rebuildTransactionItems()
    }
}
