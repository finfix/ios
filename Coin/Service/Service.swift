//
//  Service.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation
import OSLog
import SwiftUI
import Factory

private let logger = Logger(subsystem: "Coin", category: "Service")

@Observable
class Service {
    
    @ObservationIgnored @AppStorage("lastCheckedMonth") private var lastCheckedMonth: Int?
    @ObservationIgnored @AppStorage("lastCheckedYear") private var lastCheckedYear: Int?
    
    // MARK: Init
    init(
        repository: Repository,
        apiManager: APIManager,
        taskManager: TaskManager,
        authManager: AuthManager
    ) {
        self.repository = repository
        self.apiManager = apiManager
        self.taskManager = taskManager
        self.authManager = authManager
    }
    
    let repository: Repository
    let apiManager: APIManager
    let taskManager: TaskManager
    let authManager: AuthManager
}

extension Service {
    
    func checkMonthChange() async throws {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        // Сохраняем последний месяц для отслеживания изменений
        
        if currentMonth != lastCheckedMonth || currentYear != lastCheckedYear {
            
            // Обновляем сохраненные значения
            lastCheckedMonth = currentMonth
            lastCheckedYear = currentYear
            
            try await recalculateAccountBalances(accountTypes: [.balancing, .earnings, .expense])
        }
    }
    
    func reconnectGRPC(host: String, port: Int) throws {
        try apiManager.reconnect(host: host, port: port)
    }

    func deleteAllData() async throws {
        try await repository.deleteAllData()
    }
    
    func logout() async throws {
        guard try await repository.getCountTasks() == 0 else {
            throw ErrorModel(humanText: "Вам необходимо дождаться выполнения всех фоновых задач")
        }
        try await repository.deleteAllData()
        authManager.logout()
    }
        
    func joinExclusive(_ leftObjects: [Tag], _ rightObjects: [Tag]) -> ([Tag], [Tag]) {
        let leftObjectsMap = Dictionary(uniqueKeysWithValues: leftObjects.map { ($0.id, $0) })
        let rightObjectsMap = Dictionary(uniqueKeysWithValues: rightObjects.map { ($0.id, $0) })
        
        var leftObjectsExclusive: [Tag] = []
        var rightObjectsExclusive: [Tag] = []
        
        for leftObject in leftObjects {
            if rightObjectsMap[leftObject.id] == nil {
                leftObjectsExclusive.append(leftObject)
            }
        }
        
        for rightObject in rightObjects {
            if leftObjectsMap[rightObject.id] == nil {
                rightObjectsExclusive.append(rightObject)
            }
        }
        
        return (leftObjectsExclusive, rightObjectsExclusive)
    }
    
    func getStatisticByMonth(
        chartType: ChartType,
        groupBy: ChartViewGroupBy,
        period: ChartPeriod = .month,
        targetCurrency: Currency,
        accountGroupIDs: [UUID] = [],
        accountIDs: [UUID] = [],
        excludedAccountIDs: [UUID] = [],
        dateFrom: Date? = nil,
        dateTo: Date? = nil,
        tagIDs: [UUID] = [],
        currencies filterCurrencies: [Currency] = [],
        searchText: String = "",
        aggregateIntoParents: Bool = true
    ) async throws -> [Series] {
        
        // Контейнер для информации для графика
        var data: [Series] = []
        
        // Собираем все счета для дополнения идентификатора из базы
        let currencies = try await repository.getCurrencies()
        let accountsMap = Account.convertToMap(
            Account.groupAccounts(
                Account.convertFromDBModel(
                    try await repository.getAccounts(),
                    currenciesMap: Currency.convertToMap(Currency.convertFromDBModel(currencies)),
                    accountGroupsMap: nil,
                    iconsMap: nil
                ),
                saveChildren: true
            )
        )
        let tagsMap = Tag.convertToMap(
            Tag.convertFromDBModel(
                try await repository.getTags(),
                accountGroupsMap: nil
            )
        )
        

        switch chartType {
        // Если необходима разбивка по доходам/расходам
        case .earningsAndExpenses:
            
            // Получаем все расходы по периодам
            var expenses = try await repository.getStatisticByMonth(
                chartType: chartType,
                groupBy: groupBy,
                period: period,
                transactionType: .consumption,
                accountGroupIDs: accountGroupIDs,
                targetCurrency: targetCurrency,
                accountIDs: accountIDs,
                excludedAccountIDs: excludedAccountIDs,
                dateFrom: dateFrom,
                dateTo: dateTo,
                tagIDs: tagIDs,
                currencies: filterCurrencies,
                searchText: searchText
            )
            
            //
            if !expenses.isEmpty {
                expenses[0].type = .expense
                expenses[0].color = .red
                data.append(contentsOf: expenses)
            }
            
            // Получаем доходы по периодам
            var earnings = try await repository.getStatisticByMonth(
                chartType: chartType,
                groupBy: groupBy,
                period: period,
                transactionType: .income,
                accountGroupIDs: accountGroupIDs,
                targetCurrency: targetCurrency,
                accountIDs: accountIDs,
                excludedAccountIDs: excludedAccountIDs,
                dateFrom: dateFrom,
                dateTo: dateTo,
                tagIDs: tagIDs,
                currencies: filterCurrencies,
                searchText: searchText
            )
            
            //
            if !earnings.isEmpty {
                earnings[0].type = .income
                earnings[0].color = .green
                data.append(contentsOf: earnings)
            }
            
        // Если необходимо получить только данные по доходам
        case .earnings:
            
            // Получаем статистику по доходным счетам/подкатегориям
            data = try await repository.getStatisticByMonth(
                chartType: chartType,
                groupBy: groupBy,
                period: period,
                transactionType: .income,
                accountGroupIDs: accountGroupIDs,
                targetCurrency: targetCurrency,
                accountIDs: accountIDs,
                excludedAccountIDs: excludedAccountIDs,
                dateFrom: dateFrom,
                dateTo: dateTo,
                tagIDs: tagIDs,
                currencies: filterCurrencies,
                searchText: searchText
            )
            
        // Если необходимо получить только данные по расходам
        case .expenses:
            
            // Получаем статистику по расходным счетам/подкатегориям
            data = try await repository.getStatisticByMonth(
                chartType: chartType,
                groupBy: groupBy,
                period: period,
                transactionType: .consumption,
                accountGroupIDs: accountGroupIDs,
                targetCurrency: targetCurrency,
                accountIDs: accountIDs,
                excludedAccountIDs: excludedAccountIDs,
                dateFrom: dateFrom,
                dateTo: dateTo,
                tagIDs: tagIDs,
                currencies: filterCurrencies,
                searchText: searchText
            )
            
        // Дельта: совокупный доход минус совокупный расход за период, одной линией
        case .delta:

            let expenses = try await repository.getStatisticByMonth(
                chartType: .earningsAndExpenses,
                groupBy: groupBy,
                period: period,
                transactionType: .consumption,
                accountGroupIDs: accountGroupIDs,
                targetCurrency: targetCurrency,
                accountIDs: accountIDs,
                excludedAccountIDs: excludedAccountIDs,
                dateFrom: dateFrom,
                dateTo: dateTo,
                tagIDs: tagIDs,
                currencies: filterCurrencies,
                searchText: searchText
            )
            let earnings = try await repository.getStatisticByMonth(
                chartType: .earningsAndExpenses,
                groupBy: groupBy,
                period: period,
                transactionType: .income,
                accountGroupIDs: accountGroupIDs,
                targetCurrency: targetCurrency,
                accountIDs: accountIDs,
                excludedAccountIDs: excludedAccountIDs,
                dateFrom: dateFrom,
                dateTo: dateTo,
                tagIDs: tagIDs,
                currencies: filterCurrencies,
                searchText: searchText
            )

            var deltaData: [Date: Decimal] = [:]
            for series in earnings {
                for (date, value) in series.data {
                    deltaData[date, default: 0] += value
                }
            }
            for series in expenses {
                for (date, value) in series.data {
                    deltaData[date, default: 0] -= value
                }
            }
            data = [Series(account: nil, objectID: UUID(), color: .blue, data: deltaData)]

        // Текущий баланс счетов в каждый период (детально по счетам, либо одной сводной серией)
        case .balance, .balanceTotal:
            
            let currentPeriod = Date.now.startOfPeriod(period)
            
            // Загружаем группы счетов для корректной фильтрации
            let currenciesMap = Currency.convertToMap(Currency.convertFromDBModel(currencies))
            let accountGroupsMap = AccountGroup.convertToMap(
                AccountGroup.convertFromDBModel(
                    try await repository.getAccountGroups(),
                    currenciesMap: currenciesMap
                )
            )
            
            // Получаем счета типа regular и debt, участвующие в графиках
            let balanceAccounts = Account.groupAccounts(
                Account.convertFromDBModel(
                    try await repository.getAccounts(),
                    currenciesMap: currenciesMap,
                    accountGroupsMap: accountGroupsMap,
                    iconsMap: nil
                ),
                saveChildren: true
            ).filter { account in
                guard (account.type == .regular || account.type == .debt) && account.accountingInCharts else { return false }
                let groupMatch = accountGroupIDs.isEmpty || accountGroupIDs.contains(account.accountGroup.id)
                let accountMatch = accountIDs.isEmpty || accountIDs.contains(account.id)
                let excludedMatch = !excludedAccountIDs.contains(account.id)
                let currencyMatch = filterCurrencies.isEmpty || filterCurrencies.contains(account.currency)
                return groupMatch && accountMatch && excludedMatch && currencyMatch
            }

            // Получаем чистые потоки по периодам для каждого счёта
            let netFlows = try await repository.getMonthlyNetFlowByAccount(
                period: period,
                targetCurrency: targetCurrency,
                accountGroupIDs: accountGroupIDs,
                accountIDs: balanceAccounts.map(\.id)
            )
            
            for account in balanceAccounts {
                let accountFlows = netFlows[account.id] ?? [:]
                var seriesData: [Date: Decimal] = [:]
                
                // Конвертируем текущий баланс в целевую валюту
                let currencyRate = targetCurrency.rate / account.currency.rate
                var balance = account.remainder * currencyRate
                seriesData[currentPeriod] = balance.round(factor: 0)
                
                // Восстанавливаем исторический баланс, идя назад от текущего периода.
                // `currentPeriod` выровнен по UTC-полуночи (см. `startOfPeriod`), поэтому и
                // шаг назад должен считаться в UTC-календаре — иначе `.adding(...)` по
                // умолчанию берёт `Calendar.current` (локальный, чувствительный к
                // историческим сдвигам часового пояса/DST), и на датах, где абсолютное
                // смещение зоны отличалось от текущего (для Москвы это годы до 2014),
                // курсор уезжает на час и попадает не на ту UTC-полночь. В результате в
                // `seriesData` появляется два ключа на один и тот же календарный месяц:
                // "правильный" с реальным значением и паразитный на UTC-полночи с нулём —
                // и точечный поиск по дате в списке серий натыкается именно на нулевой.
                var utcCalendar = Calendar.current
                utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
                // Не восстанавливаем баланс глубже, чем просит dateFrom (например, для
                // подневного графика это ограничение в 3 месяца) — иначе для баланса это
                // ограничение молча игнорировалось и график всегда считал всю историю.
                let earliestAllowedPeriod = dateFrom?.startOfPeriod(period)
                if let earliestPeriod = accountFlows.keys.min() {
                    var cursor = currentPeriod
                    while cursor >= earliestPeriod {
                        balance -= accountFlows[cursor] ?? 0
                        cursor = cursor.adding(period.calendarComponent, value: -1, using: utcCalendar)
                        if let earliestAllowedPeriod, cursor < earliestAllowedPeriod {
                            break
                        }
                        seriesData[cursor] = balance.round(factor: 0)
                    }
                }
                
                data.append(Series(account: account, objectID: account.id, data: seriesData))
            }

            if chartType == .balanceTotal {
                // "Общий" вид: схлопываем все счета в одну сводную серию с суммарным балансом —
                // никакого сворачивания в родителей тут не нужно, просто суммируем всё подряд.
                var totalData: [Date: Decimal] = [:]
                for series in data {
                    for (date, value) in series.data {
                        totalData[date, default: 0] += value
                    }
                }
                data = [Series(account: nil, objectID: UUID(), color: .blue, data: totalData)]
            } else {
                // В отличие от доходов/расходов, баланс до этого момента никогда не сворачивал
                // дочерние счета в родительские — из-за `saveChildren: true` в `groupAccounts`
                // список всегда содержал и родителя, и каждого ребёнка отдельной серией. Теперь
                // приводим к тому же поведению: при глобальном просмотре графика (не внутри
                // конкретного родительского счёта) суммируем дочерние серии в родительскую и
                // убираем дочерние из списка — аналогично блоку для .earnings/.expenses ниже.
                if aggregateIntoParents {
                    var parentSeriesIndexMap: [UUID: Int] = [:]
                    for (i, series) in data.enumerated() {
                        if let account = series.account, account.isParent {
                            parentSeriesIndexMap[account.id] = i
                        }
                    }

                    var childIndicesToRemove: [Int] = []
                    for (i, series) in data.enumerated() {
                        guard let account = series.account, let parentID = account.parentAccountID else { continue }

                        if let parentIndex = parentSeriesIndexMap[parentID] {
                            for (date, value) in series.data {
                                data[parentIndex].data[date, default: 0] += value
                            }
                        } else if let parentAccount = balanceAccounts.first(where: { $0.id == parentID }) {
                            let parentSeries = Series(account: parentAccount, objectID: parentID, data: series.data)
                            data.append(parentSeries)
                            parentSeriesIndexMap[parentID] = data.count - 1
                        }
                        childIndicesToRemove.append(i)
                    }

                    for index in childIndicesToRemove.sorted(by: >) {
                        data.remove(at: index)
                    }
                }

                // Сортируем по текущему балансу и назначаем цвета
                data = data.sorted { ($0.data[currentPeriod] ?? 0) > ($1.data[currentPeriod] ?? 0) }
                for (i, _) in data.enumerated() {
                    data[i].serialNumber = UInt32(i)
                    data[i].color = defaultColors[i % defaultColors.count]
                }
            }
        }
        
        if chartType == .earnings || chartType == .expenses {
            switch groupBy {
            case .byAccount:
                for (i, dataItem) in data.enumerated() {
                    if let objectID = dataItem.objectID {
                        data[i].account = accountsMap[objectID]
                    }
                }
                
                if aggregateIntoParents {
                    // Первый проход: находим уже существующие родительские серии
                    var parentSeriesIndexMap: [UUID: Int] = [:]
                    for (i, series) in data.enumerated() {
                        if let account = series.account, account.isParent {
                            parentSeriesIndexMap[account.id] = i
                        }
                    }
                    
                    // Второй проход: агрегируем дочерние серии в родительские
                    var childIndicesToRemove: [Int] = []
                    for (i, series) in data.enumerated() {
                        guard let account = series.account, let parentID = account.parentAccountID else { continue }
                        
                        if let parentIndex = parentSeriesIndexMap[parentID] {
                            // Родительская серия уже есть — суммируем данные дочернего счёта
                            for (date, value) in series.data {
                                data[parentIndex].data[date, default: 0] += value
                            }
                        } else if let parentAccount = accountsMap[parentID] {
                            // Родительской серии нет (нет собственных транзакций) — создаём её
                            let parentSeries = Series(account: parentAccount, objectID: parentID, data: series.data)
                            data.append(parentSeries)
                            parentSeriesIndexMap[parentID] = data.count - 1
                        }
                        childIndicesToRemove.append(i)
                    }
                    
                    // Удаляем дочерние серии в обратном порядке, чтобы не сбить индексы
                    for index in childIndicesToRemove.sorted(by: >) {
                        data.remove(at: index)
                    }
                }
            case .byTag:
                for (i, dataItem) in data.enumerated() {
                    if let objectID = dataItem.objectID {
                        data[i].tag = tagsMap[objectID]
                    }
                }
            }
            
            data = data.sorted(by: { $0.data.map{$0.value}.reduce(0){$0+$1} > $1.data.map{$0.value}.reduce(0){$0+$1} })
            for (i, _) in data.enumerated() {
                data[i].serialNumber = UInt32(i)
                data[i].color = defaultColors[i%defaultColors.count]
            }
        }
        
        var minDate: Date = .distantFuture
        var maxDate: Date = .distantPast
        
        // Проходимся по каждой статье и получаем дату самой первой и самой последней записи
        for data in data {
            if let minDateOfData = data.data.keys.min() {
                if minDate > minDateOfData {
                    minDate = minDateOfData
                }
            }
            if let maxDateOfData = data.data.keys.max() {
                if maxDate < maxDateOfData {
                    maxDate = maxDateOfData
                }
            }
        }
        
        // UTC-календарь — даты из SQL всегда в UTC-полночь
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        
        // Проходимся по каждой статье
        for (i, series) in data.enumerated() {
            
            // Начинаем с начала периода, чтобы даты точно совпадали с ключами из БД
            var lastDate: Date = minDate.startOfPeriod(period)
            
            // Проходимся по датам в порядке увеличения, заполняя пропуски нулями
            while true {
                
                if series.data[lastDate] == nil {
                    data[i].data[lastDate] = 0
                }
                                
                // Добавляем один период через UTC-календарь
                lastDate = lastDate.adding(period.calendarComponent, value: 1, using: utcCalendar)
                if lastDate > maxDate {
                    break
                }
            }
        }
        return data
    }
    
    func compareLocalAndServerData() async throws -> String? {
        guard try await repository.getCountTasks() == 0 else {
            throw ErrorModel(humanText: "Вам необходимо дождаться выполнения всех фоновых задач")
        }
        logger.log("Начали сравнение серверных данных с локальными")
        
        var differences: String = ""
        
        // Получаем данные текущего месяца для запроса
        let (dateFrom, dateTo) = getMonthPeriodFromDate(Date.now)
        
        // Получаем все данные с сервера
        async let serverIcons = IconDB.convertFromApiModel(try await apiManager.GetIcons())
        async let serverCurrencies = CurrencyDB.convertFromApiModel(try await apiManager.GetCurrencies())
        async let serverUser = UserDB(try await apiManager.GetUser())
        async let serverAccountGroups = AccountGroupDB.convertFromApiModel(try await apiManager.GetAccountGroups())
        async let serverAccounts = AccountDB.convertFromApiModel(try await apiManager.GetAccounts(req: GetAccountsReq(dateFrom: dateFrom, dateTo: dateTo)))
        async let serverTags = TagDB.convertFromApiModel(try await apiManager.GetTags())
        async let serverTagsToTransactions = TagToTransactionDB.convertFromApiModel(try await apiManager.GetTagsToTransaction())
        async let serverTransactions = TransactionDB.convertFromApiModel(try await apiManager.GetTransactions(req: GetTransactionReq(dateFrom: Date.distantPast, dateTo: Date.distantFuture)))
        
        var localIcons = try await repository.getIcons()
        var localCurrencies = try await repository.getCurrencies()
        var localUsers = try await repository.getUsers()
        var localAccountGroups = try await repository.getAccountGroups()
        var localAccounts = try await repository.getAccounts()
        var localTags = try await repository.getTags()
        var localTagsToTransactions = try await repository.getTagsToTransactions()
        var localTransactions = try await repository.getTransactions(limit: Int.max)
                        
        let iconsDifferences = IconDB.compareTwoArrays(try await serverIcons, localIcons)
        if !iconsDifferences.isEmpty {
            differences += "Icons: \(iconsDifferences)"
            logger.warning("Icons: \(iconsDifferences)")
        }
        let currenciesDifferences = CurrencyDB.compareTwoArrays(try await serverCurrencies, localCurrencies)
        if !currenciesDifferences.isEmpty {
            differences += "\n\nCurrencies: \(currenciesDifferences)"
            logger.warning("Currencies: \(currenciesDifferences)")
        }
        let userDifferences = UserDB.compareTwoArrays(try await [serverUser], localUsers)
        if !userDifferences.isEmpty {
            differences += "\n\nUsers: \(userDifferences)"
            logger.warning("Users: \(userDifferences)")
        }
        let accountGroupsDifferences = AccountGroupDB.compareTwoArrays(try await serverAccountGroups, localAccountGroups)
        if !accountGroupsDifferences.isEmpty {
            differences += "\n\nAccountGroups: \(accountGroupsDifferences)"
            logger.warning("AccountGroups: \(accountGroupsDifferences)")
        }
        let accountsDifferences = AccountDB.compareTwoArrays(try await serverAccounts, localAccounts)
        if !accountsDifferences.isEmpty {
            differences += "\n\nAccounts: \(accountsDifferences)"
            logger.warning("Accounts: \(accountsDifferences)")
        }
        let tagsDifferences = TagDB.compareTwoArrays(try await serverTags, localTags)
        if !tagsDifferences.isEmpty {
            differences += "\n\nTags: \(tagsDifferences)"
            logger.warning("Tags: \(tagsDifferences)")
        }
        let tagsToTransactionsDifferences = TagToTransactionDB.compareTwoArrays(try await serverTagsToTransactions, localTagsToTransactions)
        if !tagsToTransactionsDifferences.isEmpty {
            differences += "\n\nTagsToTransactions: \(tagsToTransactionsDifferences)"
            logger.warning("TagsToTransactions: \(tagsToTransactionsDifferences)")
        }
        let transactionsDifferences = TransactionDB.compareTwoArrays(try await serverTransactions, localTransactions)
        if !transactionsDifferences.isEmpty {
            differences += "\n\nTransactions: \(transactionsDifferences)"
            logger.warning("Transactions: \(transactionsDifferences)")
        }
        if differences == "" {
            return nil
        } else {
            return differences
        }
    }
    
    func getCountTasks() async throws -> UInt32 {
        return try await repository.getCountTasks()
    }
    
    /// Лёгкая инкрементальная синхронизация (Sync/ConfirmSync) поверх полного sync() ниже —
    /// см. TaskManager.incrementalSync.
    func incrementalSync() async throws {
        try await taskManager.incrementalSync()
    }

    func sync() async throws {
        logger.info("Синхронизируем данные")
                
        // Получаем данные текущего месяца для запроса
        let (dateFrom, dateTo) = getMonthPeriodFromDate(Date.now)
        
        // Получаем все данные с сервера
        async let _icons = try await apiManager.GetIcons()
        async let _currencies = try await apiManager.GetCurrencies()
        async let _user = try await apiManager.GetUser()
        async let _accountGroups = try await apiManager.GetAccountGroups()
        async let _accounts = try await apiManager.GetAccounts(req: GetAccountsReq(dateFrom: dateFrom, dateTo: dateTo))
        // accountGroupIDs пустой — сервер сам ограничивает доступными пользователю группами.
        async let _accountBudgets = try await apiManager.GetAccountBudgets(req: GetAccountBudgetsReq())
        async let _tags = try await apiManager.GetTags()
        async let _tagsToTransactions = try await apiManager.GetTagsToTransaction()
        async let _transactions = try await apiManager.GetTransactions(
            req: GetTransactionReq(
                dateFrom: Date.distantPast,
                dateTo: Date.distantFuture
            )
        )

        let (icons, currencies, user, accountGroups, accounts, accountBudgets, tags, tagsToTrasnactions, transactions) = try await (_icons, _currencies, _user, _accountGroups, _accounts, _accountBudgets, _tags, _tagsToTransactions, _transactions)

        // Сохраняем иконки из gRPC ответа в локальные файлы
        logger.info("Сохраняем иконки из gRPC")
        var iconsDB: [IconDB] = []
        for icon in icons {
            guard !icon.name.isEmpty else {
                logger.warning("Пропускаем иконку \(icon.id) — пустое имя файла")
                continue
            }
            let localURL = URL.documentsDirectory.appending(path: icon.name)
            try icon.image.write(to: localURL, options: [.atomic, .completeFileProtection])
            iconsDB.append(IconDB(id: icon.id, name: icon.name, url: icon.name))
        }

        // Удаляем все данные в базе данных
        logger.info("Удаляем все данные")
        try await repository.deleteAllData()

        // Сохраняем данные в базу данных
        logger.info("Сохраняем данные по иконкам")
        try await repository.importIcons(iconsDB)
        logger.info("Сохраняем валюты")
        try await repository.importCurrencies(CurrencyDB.convertFromApiModel(currencies))
        logger.info("Сохраняем пользователя")
        try await repository.importUser(UserDB(user))
        logger.info("Сохраняем группы счетов")
        try await repository.importAccountGroups(AccountGroupDB.convertFromApiModel(accountGroups))
        logger.info("Сохраняем счета")
        try await repository.importAccounts(AccountDB.convertFromApiModel(accounts).sorted { l, _ in l.isParent })
        logger.info("Сохраняем историю бюджетов счетов")
        try await repository.importAccountBudgets(AccountBudgetDB.convertFromApiModel(accountBudgets))
        logger.info("Сохраняем подкатегории")
        try await repository.importTags(TagDB.convertFromApiModel(tags))
        logger.info("Сохраняем транзакции")
        try await repository.importTransactions(TransactionDB.convertFromApiModel(transactions))
        logger.info("Сохраняем связки между подкатегориями и транзакциями")
        try await repository.importTagsToTransactions(TagToTransactionDB.convertFromApiModel(tagsToTrasnactions))
    }
}

extension Decimal {
    public func round(factor: Int16) -> Decimal {
      let roundingBehavior = NSDecimalNumberHandler(
        roundingMode: .bankers,
        scale: factor,
        raiseOnExactness: true,
        raiseOnOverflow: true,
        raiseOnUnderflow: true,
        raiseOnDivideByZero: true
      )
    
      return (self as NSDecimalNumber).rounding(accordingToBehavior: roundingBehavior) as Decimal
    }
}
