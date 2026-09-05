//
//  Repository.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation
import GRDB
import OSLog

private let logger = Logger(subsystem: "Coin", category: "Repository")

class Repository {
    
    init(sqlite: SQLite) {
        self.sqlite = sqlite
    }
    
    private let sqlite: SQLite
    
    func importIcons(_ icons: [IconDB]) async throws {
        try await sqlite.write { db in
            for icon in icons {
                try icon.insert(db)
            }
        }
    }
    
    func importCurrencies(_ currencies: [CurrencyDB]) async throws {
        try await sqlite.write { db in
            for currency in currencies {
                try currency.insert(db)
            }
        }
    }
    
    func importUser(_ user: UserDB) async throws {
        try await sqlite.write { db in
            try user.insert(db)
        }
    }
    
    func importAccountGroups(_ accountGroups: [AccountGroupDB]) async throws {
        try await sqlite.write { db in
            for accountGroup in accountGroups {
                try accountGroup.insert(db)
            }
        }
    }
    
    func importAccounts(_ accounts: [AccountDB]) async throws {
        try await sqlite.write { db in
            for account in accounts {
                try account.insert(db)
            }
        }
    }
    
    func importTags(_ tags: [TagDB]) async throws {
        try await sqlite.write { db in
            for tag in tags {
                try tag.insert(db)
            }
        }
    }
    
    func importTagsToTransactions(_ tagsToTransactions: [TagToTransactionDB]) async throws {
        try await sqlite.write { db in
            for tagToTransaction in tagsToTransactions {
                try tagToTransaction.insert(db)
            }
        }
    }
    
    func importTransactions(_ transactions: [TransactionDB]) async throws {
        try await sqlite.write { db in
            for transaction in transactions {
                try transaction.insert(db)
            }
        }
    }

    func importAccountBudgets(_ budgets: [AccountBudgetDB]) async throws {
        try await sqlite.write { db in
            for budget in budgets {
                try budget.insert(db)
            }
        }
    }

    // sourceTransactionID — belongsTo FK на transactionDB, поэтому вызывать ПОСЛЕ importTransactions.
    func importPendingLinkedTransfers(_ transfers: [PendingLinkedTransferDB]) async throws {
        try await sqlite.write { db in
            for transfer in transfers {
                try transfer.insert(db)
            }
        }
    }

    // Применяет дельту инкрементального Sync одной локальной транзакцией (см.
    // TaskManager.incrementalSync): апсертит изменённые сущности (.save — записи могут уже
    // существовать), затем удаляет по id. Порядок вставки/удаления соблюдает те же
    // FK-зависимости, что и deleteAllData/Service.sync (группы → счета → теги → транзакции →
    // бюджеты, с родительскими счетами раньше дочерних).
    //
    // Возвращает id счетов, задействованных в изменённых/удалённых транзакциях — remainder
    // этих счетов в accountDB после Sync может быть устаревшим (сервер прислал изменённые
    // счета только если поменялись ИХ поля, а не при каждой транзакции по ним), поэтому вызывающий
    // код (TaskManager.incrementalSync → Service.recalculateAccountBalances) должен пересчитать
    // балансы именно этих счетов — точно так же, как при локальном создании/изменении/удалении
    // транзакции (см. TransactionService.swift).
    @discardableResult
    func applySyncChanges(_ res: SyncRes) async throws -> Set<UUID> {
        try await sqlite.write { db in
            var affectedAccountIDs: Set<UUID> = []
            for transaction in res.changedTransactions {
                affectedAccountIDs.insert(transaction.accountFromID)
                affectedAccountIDs.insert(transaction.accountToID)
            }
            if !res.deletedTransactionIDs.isEmpty {
                // Счета удаляемых транзакций нужно узнать ДО удаления строк.
                let deletedTransactions = try TransactionDB
                    .filter(res.deletedTransactionIDs.contains(TransactionDB.Columns.id))
                    .fetchAll(db)
                for transaction in deletedTransactions {
                    affectedAccountIDs.insert(transaction.accountFromId)
                    affectedAccountIDs.insert(transaction.accountToId)
                }
            }

            if let changedUser = res.changedUser {
                try UserDB(changedUser).save(db)
            }
            for currency in CurrencyDB.convertFromApiModel(res.changedCurrencies) {
                try currency.save(db)
            }
            for accountGroup in AccountGroupDB.convertFromApiModel(res.changedAccountGroups) {
                try accountGroup.save(db)
            }
            for account in AccountDB.convertFromApiModel(res.changedAccounts).sorted(by: { l, _ in l.isParent }) {
                try account.save(db)
            }
            for tag in TagDB.convertFromApiModel(res.changedTags) {
                try tag.save(db)
            }
            for transaction in TransactionDB.convertFromApiModel(res.changedTransactions) {
                try transaction.save(db)
            }
            for budget in AccountBudgetDB.convertFromApiModel(res.changedAccountBudgets) {
                try budget.save(db)
            }
            for transfer in PendingLinkedTransferDB.convertFromApiModel(res.changedPendingLinkedTransfers) {
                try transfer.save(db)
            }

            if !res.deletedPendingLinkedTransferIDs.isEmpty {
                try PendingLinkedTransferDB.filter(res.deletedPendingLinkedTransferIDs.contains(PendingLinkedTransferDB.Columns.id)).deleteAll(db)
            }
            if !res.deletedTransactionIDs.isEmpty {
                try TransactionDB.filter(res.deletedTransactionIDs.contains(TransactionDB.Columns.id)).deleteAll(db)
            }
            if !res.deletedAccountIDs.isEmpty {
                try AccountDB.filter(res.deletedAccountIDs.contains(AccountDB.Columns.id)).deleteAll(db)
            }
            if !res.deletedTagIDs.isEmpty {
                try TagDB.filter(res.deletedTagIDs.contains(TagDB.Columns.id)).deleteAll(db)
            }
            if !res.deletedAccountGroupIDs.isEmpty {
                try AccountGroupDB.filter(res.deletedAccountGroupIDs.contains(AccountGroupDB.Columns.id)).deleteAll(db)
            }

            return affectedAccountIDs
        }
    }

    // Пересчитывает remainder набора счетов по id — тот же алгоритм, что и
    // Service.recalculateAccountBalances (expense/earnings/balancing — в рамках текущего
    // месяца, остальные типы — за всё время), но не зависит от Service, чтобы им мог
    // пользоваться TaskManager сразу после применения инкрементального Sync.
    func recalculateBalances(accountIDs: [UUID]) async throws {
        guard !accountIDs.isEmpty else { return }

        let accounts = try await getAccounts(ids: accountIDs)

        let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let dateFrom = Calendar.current.date(from: DateComponents(year: today.year, month: today.month, day: 1))
        let dateTo = Calendar.current.date(from: DateComponents(year: today.year, month: today.month! + 1, day: 1))

        var balances: [UUID: Decimal] = [:]

        let monthWindowIDs = accounts.filter { $0.type == .expense || $0.type == .earnings || $0.type == .balancing }.compactMap(\.id)
        if !monthWindowIDs.isEmpty {
            let monthWindowBalances = try await getBalances(accountIDs: monthWindowIDs, dateFrom: dateFrom, dateTo: dateTo)
            balances = balances.merging(monthWindowBalances) { current, _ in current }
        }

        let allTimeIDs = accounts.filter { $0.type == .regular || $0.type == .debt }.compactMap(\.id)
        if !allTimeIDs.isEmpty {
            let allTimeBalances = try await getBalances(accountIDs: allTimeIDs)
            balances = balances.merging(allTimeBalances) { current, _ in current }
        }

        for (accountID, balance) in balances {
            try await updateBalance(id: accountID, newBalance: balance.round(factor: 7))
        }
    }

    func deleteAllData() async throws {
        try await sqlite.write { db in
            _ = try TagToTransactionDB.deleteAll(db)
            _ = try TransactionDB.deleteAll(db)
            _ = try AccountBudgetDB.deleteAll(db)
            _ = try AccountDB.deleteAll(db)
            _ = try TagDB.deleteAll(db)
            _ = try AccountGroupDB.deleteAll(db)
            _ = try UserDB.deleteAll(db)
            _ = try CurrencyDB.deleteAll(db)
            _ = try IconDB.deleteAll(db)
            _ = try SyncTaskDB.deleteAll(db)
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) async throws {
        try await sqlite.write { db in
            _ = try TransactionDB(transaction).delete(db)
        }
    }
    
    func deleteTag(_ tag: Tag) async throws {
        try await sqlite.write { db in
            _ = try TagDB(tag).delete(db)
        }
    }
    
    func createAccount(_ account: Account) async throws {
        try await sqlite.write { db in
            try AccountDB(account).insert(db)
        }
    }

    func createAccountBudget(_ budget: AccountBudget) async throws {
        try await sqlite.write { db in
            try AccountBudgetDB(budget).insert(db)
        }
    }

    // Все версии бюджета (всех счетов), опционально отфильтрованные по конкретным счетам —
    // резолв "какая версия действует на дату X" делается уже в Service, чисто в памяти,
    // поскольку версий на счёт обычно немного.
    func getAccountBudgets(accountIDs: [UUID]? = nil) async throws -> [AccountBudgetDB] {
        try await sqlite.read { db in
            var request = AccountBudgetDB.order(AccountBudgetDB.Columns.effectiveFrom.desc)
            if let accountIDs {
                request = request.filter(accountIDs.contains(AccountBudgetDB.Columns.accountId))
            }
            return try request.fetchAll(db)
        }
    }

    func updateAccount(_ account: Account) async throws {
        try await sqlite.write { db in
            _ = try AccountDB(account).update(db)
        }
    }
    
    func createPendingLinkedTransfer(_ transfer: PendingLinkedTransfer) async throws {
        try await sqlite.write { db in
            try PendingLinkedTransferDB(transfer).insert(db)
        }
    }

    func updatePendingLinkedTransfer(_ transfer: PendingLinkedTransfer) async throws {
        try await sqlite.write { db in
            _ = try PendingLinkedTransferDB(transfer).update(db)
        }
    }

    /// Переносы, у которых эта транзакция — источник (belongsTo sourceTransaction, реальный
    /// FK локально) — нужно проверять перед жёстким удалением транзакции, иначе БД откажет.
    func getPendingLinkedTransfers(sourceTransactionID: UUID) async throws -> [PendingLinkedTransfer] {
        try await sqlite.read { db in
            PendingLinkedTransfer.convertFromDBModel(
                try PendingLinkedTransferDB
                    .filter(PendingLinkedTransferDB.Columns.sourceTransactionID == sourceTransactionID)
                    .fetchAll(db)
            )
        }
    }

    func deletePendingLinkedTransfer(_ transfer: PendingLinkedTransfer) async throws {
        try await sqlite.write { db in
            _ = try PendingLinkedTransferDB(transfer).delete(db)
        }
    }

    // accountGroupID хранит группу-ИСТОЧНИК (см. proto-комментарий), поэтому фильтр по своим
    // группам находит только переносы, где я источник. Чтобы увидеть и те, где я получатель
    // (мост среди моих счетов, но в чужой группе), нужен ИЛИ по targetAccountID — отсюда OR,
    // а не последовательные .filter (те дают AND).
    //
    // Пустые accountGroupIDs/targetAccountIDs означают "мои — все, что есть локально": локально
    // синхронизированы только МОИ группы/счета, поэтому подзапрос по всей accountGroupDB/accountDB
    // корректно означает "любая моя группа"/"любой мой счёт", и остаётся живым при появлении
    // новых групп/счетов, в отличие от фиксированного списка id на момент вызова.
    func observePendingLinkedTransfers(accountGroupIDs: [UUID] = [], targetAccountIDs: [UUID] = []) -> AsyncValueObservation<[PendingLinkedTransfer]> {
        sqlite.observe { db in
            let request: QueryInterfaceRequest<PendingLinkedTransferDB>
            if accountGroupIDs.isEmpty && targetAccountIDs.isEmpty {
                request = PendingLinkedTransferDB.filter(sql: """
                    accountGroupID IN (SELECT id FROM accountGroupDB)
                    OR targetAccountID IN (SELECT id FROM accountDB)
                    """)
            } else {
                request = PendingLinkedTransferDB.filter(
                    accountGroupIDs.contains(PendingLinkedTransferDB.Columns.accountGroupID) ||
                    targetAccountIDs.contains(PendingLinkedTransferDB.Columns.targetAccountID)
                )
            }
            let all = try PendingLinkedTransferDB.fetchAll(db)
            let matched = try request.fetchAll(db)
            logger.debug("observePendingLinkedTransfers: accountGroupIDs=\(accountGroupIDs.map { $0.uuidString.prefix(8).description }, privacy: .public) targetAccountIDs=\(targetAccountIDs.map { $0.uuidString.prefix(8).description }, privacy: .public) totalRowsInTable=\(all.count) matched=\(matched.count)")
            for row in all {
                logger.debug("  row: accountGroupID=\(row.accountGroupID.uuidString.prefix(8).description, privacy: .public) targetAccountID=\(row.targetAccountID.uuidString.prefix(8).description, privacy: .public) status=\(row.status.rawValue, privacy: .public)")
            }
            return PendingLinkedTransfer.convertFromDBModel(matched)
        }
    }

    func updateTag(_ tag: Tag) async throws {
        try await sqlite.write { db in
            _ = try TagDB(tag).update(db)
        }
    }
    
    func updateUser(_ user: User) async throws {
        try await sqlite.write { db in
            _ = try UserDB(user).update(db)
        }
    }
    
    func deleteAccount(_ account: Account) async throws {
        try await sqlite.write { db in
            _ = try AccountDB(account).delete(db)
        }
    }
    
    func updateBalance(id: UUID, newBalance: Decimal) async throws {
        try await sqlite.write { db in
            
            let sql = """
                UPDATE accountDB
                SET remainder = CASE
                                 WHEN type = 'earnings' THEN ? * -1
                                 ELSE ?
                              END
                WHERE id = ?;
            """
            _ = try db.execute(sql: sql, arguments: [newBalance, newBalance, id])
        }
    }
    
    func createTransaction(_ transaction: Transaction) async throws {
        try await sqlite.write { db in
            try TransactionDB(transaction).insert(db)
        }
    }
    
    func createTag(_ tag: Tag) async throws {
        try await sqlite.write { db in
            try TagDB(tag).insert(db)
        }
    }
    
    func linkTagsToTransaction(_ tags: [Tag], transaction: Transaction) async throws {
        try await sqlite.write { db in
            for tag in tags {
                _ = try TagToTransactionDB(transactionID: transaction.id, tagID: tag.id).insert(db)
            }
        }
    }
    
    func unlinkTagsFromTransaction(_ tags: [Tag], transaction: Transaction) async throws {
        try await sqlite.write { db in
            for tag in tags {
                _ = try TagToTransactionDB(transactionID: transaction.id, tagID: tag.id).delete(db)
            }
        }
    }
    
    func updateTransaction(_ transaction: Transaction) async throws {
        try await sqlite.write { db in
            _ = try TransactionDB(transaction).update(db)
        }
    }
    
    func updateAccountGroup(_ accountGroup: AccountGroup) async throws {
        try await sqlite.write { db in
            _ = try AccountGroupDB(accountGroup).update(db)
        }
    }
    
    func deleteAccountGroup(_ accountGroup: AccountGroup) async throws {
        try await sqlite.write { db in
            _ = try AccountGroupDB(accountGroup).delete(db)
        }
    }
    
    func createAccountGroup(_ accountGroup: AccountGroup) async throws {
        try await sqlite.write { db in
            try AccountGroupDB(accountGroup).insert(db)
        }
    }

    
    func getAvailableIDForAccount() async throws -> UInt32 {
        try await sqlite.read { db in
            return try Row.fetchOne(db, sql: "SELECT MAX(id) + 1 as max FROM AccountDB")!["max"]
        }
    }
    
    func getCurrencies(searchText: String = "") async throws -> [CurrencyDB] {
        try await sqlite.read { db in
            
            var request = CurrencyDB.order(CurrencyDB.Columns.code)
            
            if !searchText.isEmpty {
                let pattern = "%\(searchText)%"
                request = request.filter(sql: "lowerUnicode(code) LIKE lowerUnicode(?) OR lowerUnicode(name) LIKE lowerUnicode(?)", arguments: [pattern, pattern])
            }

            return try request.fetchAll(db)
        }
    }
    
    func getUsers() async throws -> [UserDB] {
        try await sqlite.read { db in
            return try UserDB.fetchAll(db)
        }
    }
    
    // Считает только невыполненные таски — используется как гейт перед операциями,
    // которым нужно дождаться окончания фоновой синхронизации (см. compareLocalAndServerData).
    func getCountTasks() async throws -> UInt32 {
        try await sqlite.read { db in
            return UInt32(try SyncTaskDB.filter(!SyncTaskDB.Columns.completed).fetchCount(db))
        }
    }

    // Помечает таски выполненными вместо физического удаления — так их можно показать
    // в списке по переключателю "Показать выполненные" вместо безвозвратной потери истории.
    func completeTasks(
        ids: [UUID]? = nil
    ) async throws {
        try await sqlite.write { db in

            var request = SyncTaskDB.filter(SyncTaskDB.Columns.id != 0)
            if let ids {
                request = request.filter(ids.contains(SyncTaskDB.Columns.id))
            }

            _ = try request.updateAll(db, SyncTaskDB.Columns.completed.set(to: true))
        }
    }

    func getSyncTasks(
        ids: [UUID]? = nil,
        limit: UInt32? = nil,
        includeCompleted: Bool = false
    ) async throws -> [SyncTask] {
        try await sqlite.read { db in

            var request = SyncTaskDB
                .order(SyncTaskDB.Columns.datetimeCreate)

            if !includeCompleted {
                request = request.filter(!SyncTaskDB.Columns.completed)
            }

            if let limit {
                request = request.limit(Int(limit))
            }

            if let ids {
                request = request.filter(ids.contains(SyncTaskDB.Columns.id))
            }
            
            let syncTaskDBs = try request.fetchAll(db)
            
            var syncTasksIDs: [UUID] = []
            for syncTaskDB in syncTaskDBs {
                syncTasksIDs.append(syncTaskDB.id!)
            }
            
            var questionsArr: [String] = []
            for _ in 0..<syncTaskDBs.count {
                questionsArr.append("?")
            }
                                    
            return try SyncTask.convertFromDBModel(syncTaskDBs)
        }
    }

    /// Живой список тасок (см. SQLite.observe) — первый экран, переведённый на ValueObservation
    /// вместо ручного load()/.task/.refreshable: обновляется сам на любой коммит в syncTaskDB,
    /// откуда бы он ни пришёл (executeDBTasks, createTask, incrementalSync).
    func observeSyncTasks(includeCompleted: Bool) -> AsyncValueObservation<[SyncTask]> {
        sqlite.observe { db in
            var request = SyncTaskDB.order(SyncTaskDB.Columns.datetimeCreate)
            if !includeCompleted {
                request = request.filter(!SyncTaskDB.Columns.completed)
            }
            return try SyncTask.convertFromDBModel(request.fetchAll(db))
        }
    }

    /// Живая одна таска по id (для TaskDetails) — nil, если таску удалили (completeTasks).
    /// includeCompleted всегда true: экран должен показать финальное состояние, а не пропасть.
    func observeSyncTask(id: UUID) -> AsyncValueObservation<SyncTask?> {
        sqlite.observe { db in
            guard let taskDB = try SyncTaskDB.filter(SyncTaskDB.Columns.id == id).fetchOne(db) else {
                return nil
            }
            return try SyncTask(taskDB)
        }
    }

    func getIcons() async throws -> [IconDB] {
        try await sqlite.read { db in
            return try IconDB.fetchAll(db)
        }
    }
    
    func getAccountGroups(
        name: String? = nil
    ) async throws -> [AccountGroupDB] {
        try await sqlite.read { db in
            
            var request = AccountGroupDB.order(AccountGroupDB.Columns.serialNumber)
            
            if let name {
                request = request.filter(sql: "lowerUnicode(name) LIKE lowerUnicode(?)", arguments: ["%\(name)%"])
            }
            
            return try request.fetchAll(db)
        }
    }
    
    func getBalances(
        accountIDs: [UUID] = [],
        dateFrom: Date? = nil,
        dateTo: Date? = nil,
        accountTypes: [AccountType] = [],
        accountGroupIDs: [UUID] = []
    ) async throws -> [UUID: Decimal] {
        try await sqlite.read { db in
            
            if accountIDs.isEmpty && accountTypes.isEmpty && accountGroupIDs.isEmpty {
                return [:]
            }
            
            var dateFilter = ""
            var filters: [String] = []
            var joins: [String] = []
            var args: StatementArguments = []
            var accountsJoined = false
            
            if let dateFrom = dateFrom {
                dateFilter += "AND dateTransaction >= ?"
                _ = args.append(contentsOf: [dateFrom])
            }
            
            if let dateTo = dateTo {
                dateFilter += "\nAND dateTransaction < ?"
                _ = args.append(contentsOf: [dateTo])
            }
            
            if let dateFrom = dateFrom {
                _ = args.append(contentsOf: [dateFrom])
            }
            
            if let dateTo = dateTo {
                _ = args.append(contentsOf: [dateTo])
            }
            
            if !accountTypes.isEmpty {
                var qs: [String] = []
                for _ in accountTypes {
                    qs.append("?")
                }
                joins.append("JOIN accountDB a ON a.Id = t.accountId")
                accountsJoined = true
                filters.append("a.type in (\(qs.joined(separator: ",")))")
                _ = args.append(contentsOf: StatementArguments(accountTypes.map(\.rawValue)))
            }
            
            if !accountIDs.isEmpty {
                var qs: [String] = []
                for _ in accountIDs {
                    qs.append("?")
                }
                if !accountsJoined {
                    joins.append("JOIN accountDB a ON a.id = t.accountId")
                }
                filters.append("a.id in (\(qs.joined(separator: ",")))")
                _ = args.append(contentsOf: StatementArguments(accountIDs))
            }
            
            if !accountGroupIDs.isEmpty {
                var qs: [String] = []
                for _ in accountIDs {
                    qs.append("?")
                }
                if !accountsJoined {
                    joins.append("JOIN accountDB a ON a.id = t.accountId")
                }
                filters.append("a.accountGroupId in (\(qs.joined(separator: ",")))")
                _ = args.append(contentsOf: StatementArguments(accountGroupIDs))
            }
            
            let req = """
                SELECT 
                    accountId,
                    (
                        SELECT COALESCE(SUM(amountTo), 0)
                        FROM transactionDB
                        WHERE accountToId = t.accountId
                        \(dateFilter)
                    ) - (
                        SELECT COALESCE(SUM(amountFrom), 0)
                        FROM transactionDB
                        WHERE accountFromId = t.accountId
                        \(dateFilter)
                    ) AS remainder
                FROM (
                    SELECT DISTINCT accountToId AS accountId FROM transactionDB
                    UNION
                    SELECT DISTINCT accountFromId AS accountId FROM transactionDB
                ) AS t
                \(joins.joined(separator: "\n"))
                \(!filters.isEmpty ? "WHERE \(filters.joined(separator: "\nAND"))" : "")
                """
            
            var accountBalances: [UUID: Decimal] = [:]
            
            print(req)
            print(args)
            let rows = try Row.fetchCursor(db, sql: req, arguments: args)
            while let row = try rows.next() {
                accountBalances[row["accountId"]] = row["remainder"]
            }
            
            return accountBalances
        }
    }
    
    func getTags(
        accountGroupID: UUID? = nil,
        name: String? = nil
    ) async throws -> [TagDB] {
        try await sqlite.read { db in
            var request = TagDB.order(TagDB.Columns.id)
            if let accountGroupID {
                request = request.filter(TagDB.Columns.accountGroupID == accountGroupID)
            }
            if let name {
                request = request.filter(sql: "lowerUnicode(name) LIKE lowerUnicode(?)", arguments: ["%\(name)%"])
            }
            return try request.fetchAll(db)
        }
    }
    
    func getTagsToTransactions() async throws -> [TagToTransactionDB] {
        try await sqlite.read { db in
            return try TagToTransactionDB.fetchAll(db)
        }
    }
    
    /// Строит запрос счетов по фильтрам — общая часть между обычным getAccounts и живым
    /// observeAccounts. Чисто синхронная (просто собирает QueryInterfaceRequest, ничего не
    /// исполняет), поэтому годится и для ValueObservation.tracking.
    private func accountsQuery(
        ids: [UUID]?,
        accountGroupIDs: [UUID]?,
        visible: Bool?,
        accountingInHeader: Bool?,
        types: [AccountType]?,
        currencyCode: String?,
        isParent: Bool?,
        name: String?
    ) -> QueryInterfaceRequest<AccountDB> {
        var request = AccountDB
            .order(AccountDB.Columns.rank)

        if let ids {
            request = request.filter(keys: ids)
        }

        if let accountGroupIDs {
            request = request.filter(accountGroupIDs.contains(AccountDB.Columns.accountGroupId))
        }

        if let visible {
            request = request.filter(AccountDB.Columns.visible == visible)
        }

        if let accountingInHeader {
            request = request.filter(AccountDB.Columns.accountingInHeader == accountingInHeader)
        }

        if let currencyCode {
            request = request.filter(AccountDB.Columns.currencyCode == currencyCode)
        }

        if let isParent {
            request = request.filter(AccountDB.Columns.isParent == isParent)
        }

        if let name {
            request = request.filter(sql: "lowerUnicode(name) LIKE lowerUnicode(?)", arguments: ["%\(name)%"])
        }

        if let types {
            request = request.filter(types.map(\.rawValue).contains(AccountDB.Columns.type))
        }

        return request
    }

    func getAccounts(
        ids: [UUID]? = nil,
        accountGroupIDs: [UUID]? = nil,
        visible: Bool? = nil,
        accountingInHeader: Bool? = nil,
        types: [AccountType]? = nil,
        currencyCode: String? = nil,
        isParent: Bool? = nil,
        name: String? = nil
    ) async throws -> [AccountDB] {
        try await sqlite.read { [self] db in
            try accountsQuery(
                ids: ids, accountGroupIDs: accountGroupIDs, visible: visible,
                accountingInHeader: accountingInHeader, types: types,
                currencyCode: currencyCode, isParent: isParent, name: name
            ).fetchAll(db)
        }
    }

    /// Живой список счетов (для AccountCirclesViewModel) — уже с резолвленными
    /// currency/accountGroup/icon/effective-бюджетом, ровно как AccountService.getAccounts, но
    /// синхронно внутри ValueObservation.tracking. Группировку родитель/дети (Account.groupAccounts)
    /// сюда намеренно не тащим — это чистая Swift-агрегация без обращения к БД, ей место в
    /// вызывающем коде (как и раньше).
    func observeAccounts(accountGroupIDs: [UUID]?, visible: Bool?, accountingInHeader: Bool? = nil) -> AsyncValueObservation<[Account]> {
        sqlite.observe { [self] db in
            let accountsDB = try accountsQuery(
                ids: nil, accountGroupIDs: accountGroupIDs, visible: visible,
                accountingInHeader: accountingInHeader, types: nil, currencyCode: nil, isParent: nil, name: nil
            ).fetchAll(db)

            let iconsMap = Dictionary(uniqueKeysWithValues: try IconDB.fetchAll(db).compactMap { icon -> (UUID, Icon)? in
                guard let id = icon.id else { return nil }
                return (id, Icon(icon))
            })
            let currenciesDB = try CurrencyDB.fetchAll(db)
            let currenciesMap = Dictionary(uniqueKeysWithValues: currenciesDB.map { ($0.code, Currency($0)) })
            let accountGroupsMap = Dictionary(uniqueKeysWithValues: try AccountGroupDB.fetchAll(db).compactMap { group -> (UUID, AccountGroup)? in
                guard let id = group.id else { return nil }
                return (id, AccountGroup(group, currenciesMap: currenciesMap))
            })

            // Резолв действующей версии бюджета — та же логика, что и
            // AccountBudgetService.effectiveAccountBudgets, только синхронно.
            let accountIDs = accountsDB.compactMap(\.id)
            let budgetsDB = try AccountBudgetDB
                .filter(accountIDs.contains(AccountBudgetDB.Columns.accountId))
                .order(AccountBudgetDB.Columns.effectiveFrom.desc)
                .fetchAll(db)
            let now = Date.now
            var budgetsMap: [UUID: AccountBudget] = [:]
            for budgetDB in budgetsDB {
                let budget = AccountBudget(budgetDB)
                guard budget.effectiveFrom <= now, budgetsMap[budget.accountID] == nil else { continue }
                budgetsMap[budget.accountID] = budget
            }

            return Account.convertFromDBModel(
                accountsDB,
                currenciesMap: currenciesMap,
                accountGroupsMap: accountGroupsMap,
                iconsMap: iconsMap,
                budgetsMap: budgetsMap
            )
        }
    }
    
    /// Строит SQL/аргументы для выборки транзакций по фильтрам — общая часть между обычным
    /// (async) getTransactions и живым observeTransactionRows, чтобы не дублировать построение
    /// WHERE/JOIN в двух местах. Чисто синхронная (без обращения к db), чтобы её можно было
    /// использовать и внутри ValueObservation.tracking.
    private func transactionsSQL(
        limit: Int,
        offset: Int,
        ids: [UUID],
        dateFrom: Date?,
        dateTo: Date?,
        searchText: String,
        accountIDs: [UUID],
        excludedAccountIDs: [UUID],
        accountGroupIDs: [UUID],
        transactionTypes: [TransactionType],
        currencies: [Currency],
        tagIDs: [UUID],
        excludedTagIDs: [UUID] = []
    ) -> (sql: String, args: StatementArguments) {
        var joins: [String] = []
            var filters: [String] = []
            var args: StatementArguments = []

            if !ids.isEmpty {
                var questions: [String] = []
                for _ in ids {
                    questions.append("?")
                }
                filters.append("t.id IN (\(questions.joined(separator: ",")))")
                _ = args.append(contentsOf: StatementArguments(ids))
            }

            if let dateFrom {
                filters.append("t.dateTransaction >= ?")
                _ = args.append(contentsOf: [dateFrom])
            }

            if let dateTo {
                filters.append("t.dateTransaction <= ?")
                _ = args.append(contentsOf: [dateTo])
            }

            if searchText != "" {
                filters.append("lowerUnicode(t.note) LIKE lowerUnicode(?)")
                _ = args.append(contentsOf: ["%"+searchText+"%"])
            }

            if !accountIDs.isEmpty {

                var questions: [String] = []
                for _ in accountIDs {
                    questions.append("?")
                }

                filters.append("(t.accountFromId IN (\(questions.joined(separator: ","))) OR t.accountToId IN (\(questions.joined(separator: ","))))")
                _ = args.append(contentsOf: StatementArguments(accountIDs))
                _ = args.append(contentsOf: StatementArguments(accountIDs))
            }

            if !excludedAccountIDs.isEmpty {

                var questions: [String] = []
                for _ in excludedAccountIDs {
                    questions.append("?")
                }

                filters.append("(t.accountFromId NOT IN (\(questions.joined(separator: ","))) AND t.accountToId NOT IN (\(questions.joined(separator: ","))))")
                _ = args.append(contentsOf: StatementArguments(excludedAccountIDs))
                _ = args.append(contentsOf: StatementArguments(excludedAccountIDs))
            }

            if !accountGroupIDs.isEmpty {
                
                var questions: [String] = []
                for _ in accountGroupIDs {
                    questions.append("?")
                }
                
                filters.append("t.accountGroupId IN (\(questions.joined(separator: ",")))")
                _ = args.append(contentsOf: StatementArguments(accountGroupIDs))
            }
            
            if !tagIDs.isEmpty {
                
                var questions: [String] = []
                for _ in tagIDs {
                    questions.append("?")
                }
                
                joins.append("JOIN tagToTransactionDB tttd ON tttd.transactionId = t.id")
                joins.append("JOIN tagDB tg ON tttd.tagId = tg.id")
                
                filters.append("tg.id IN (\(questions.joined(separator: ",")))")
                _ = args.append(contentsOf: StatementArguments(tagIDs))
            }

            if !excludedTagIDs.isEmpty {
                var questions: [String] = []
                for _ in excludedTagIDs {
                    questions.append("?")
                }
                // NOT EXISTS, а не JOIN + NOT IN — у транзакции может быть несколько тегов
                // (many-to-many), а "исключить" должно значить "скрыть транзакцию целиком, если
                // среди ЛЮБЫХ её тегов есть исключённый", а не просто отфильтровать одну из
                // строк JOIN'а. Отдельный алиас (ex_tttd), чтобы не столкнуться с tttd/tg,
                // который использует tagIDs (включающий фильтр) выше.
                filters.append("""
                    NOT EXISTS (
                        SELECT 1 FROM tagToTransactionDB ex_tttd
                        WHERE ex_tttd.transactionId = t.id AND ex_tttd.tagId IN (\(questions.joined(separator: ",")))
                    )
                    """)
                _ = args.append(contentsOf: StatementArguments(excludedTagIDs))
            }

            if !transactionTypes.isEmpty {
                var questions: [String] = []
                for _ in transactionTypes {
                    questions.append("?")
                }

                filters.append("t.type IN (\(questions.joined(separator: ",")))")
                _ = args.append(contentsOf: StatementArguments(transactionTypes.map(\.rawValue)))
            }

            if !currencies.isEmpty {
                var questions: [String] = []
                for _ in currencies {
                    questions.append("?")
                }

                joins.append("JOIN accountDB a1 ON a1.id = t.accountFromId")
                joins.append("JOIN accountDB a2 ON a2.id = t.accountToId")

            filters.append("(a1.currencyCode IN (\(questions.joined(separator: ","))) OR a2.currencyCode IN (\(questions.joined(separator: ","))))")
            _ = args.append(contentsOf: StatementArguments(currencies.map(\.code)))
            _ = args.append(contentsOf: StatementArguments(currencies.map(\.code)))
        }

        let sql = """
            SELECT *
            FROM transactionDB t
            \(joins.joined(separator: "\n"))
            \(filters.isEmpty ? "" : "WHERE \(filters.joined(separator: "\nAND "))")
            ORDER BY t.dateTransaction DESC, t.datetimeCreate DESC
            LIMIT \(limit) OFFSET \(offset)
        """

        return (sql, args)
    }

    func getTransactions(
        limit: Int = 100,
        offset: Int = 0,
        ids: [UUID] = [],
        dateFrom: Date? = nil,
        dateTo: Date? = nil,
        searchText: String = "",
        accountIDs: [UUID] = [],
        excludedAccountIDs: [UUID] = [],
        accountGroupIDs: [UUID] = [],
        transactionTypes: [TransactionType] = [],
        currencies: [Currency] = [],
        tagIDs: [UUID] = [],
        excludedTagIDs: [UUID] = []
    ) async throws -> [TransactionDB] {
        try await sqlite.read { [self] db in
            let (sql, args) = transactionsSQL(
                limit: limit, offset: offset, ids: ids, dateFrom: dateFrom, dateTo: dateTo,
                searchText: searchText, accountIDs: accountIDs, excludedAccountIDs: excludedAccountIDs,
                accountGroupIDs: accountGroupIDs, transactionTypes: transactionTypes,
                currencies: currencies, tagIDs: tagIDs, excludedTagIDs: excludedTagIDs
            )
            return try TransactionDB.fetchAll(db, sql: sql, arguments: args)
        }
    }

    /// Живое окно списка транзакций (для TransactionsList) — в отличие от пагинации, ничего не
    /// подгружает само: наблюдает ровно тот диапазон [dateFrom, dateTo], что уже реально загружен
    /// на экране (нижняя граница — курсор пагинации), и переотдаёт TransactionListRowData сразу
    /// с именами/валютами счетов и тегами, чтобы вьюмодели не пришлось повторно джойнить их в
    /// Swift. limit здесь достаточно большой (не пагинация) — просто верхняя защита от аномально
    /// огромного окна.
    func observeTransactionRows(
        dateFrom: Date?,
        dateTo: Date?,
        searchText: String,
        accountIDs: [UUID],
        excludedAccountIDs: [UUID],
        accountGroupIDs: [UUID],
        transactionTypes: [TransactionType],
        currencies: [Currency],
        tagIDs: [UUID],
        excludedTagIDs: [UUID] = []
    ) -> AsyncValueObservation<[TransactionListRowData]> {
        sqlite.observe { [self] db in
            let (sql, args) = transactionsSQL(
                limit: 10000, offset: 0, ids: [], dateFrom: dateFrom, dateTo: dateTo,
                searchText: searchText, accountIDs: accountIDs, excludedAccountIDs: excludedAccountIDs,
                accountGroupIDs: accountGroupIDs, transactionTypes: transactionTypes,
                currencies: currencies, tagIDs: tagIDs, excludedTagIDs: excludedTagIDs
            )
            let transactionsDB = try TransactionDB.fetchAll(db, sql: sql, arguments: args)

            let accountIDsNeeded = Set(transactionsDB.flatMap { [$0.accountFromId, $0.accountToId] })
            let accountsDB = try AccountDB.filter(accountIDsNeeded.contains(AccountDB.Columns.id)).fetchAll(db)
            let accountMap = Dictionary(uniqueKeysWithValues: accountsDB.compactMap { account -> (UUID, AccountDB)? in
                guard let id = account.id else { return nil }
                return (id, account)
            })

            let currencyCodesNeeded = Set(accountsDB.map(\.currencyCode))
            let currenciesDB = try CurrencyDB.filter(currencyCodesNeeded.contains(CurrencyDB.Columns.code)).fetchAll(db)
            let currencyMap = Dictionary(uniqueKeysWithValues: currenciesDB.map { ($0.code, Currency($0)) })

            let transactionIDs = transactionsDB.compactMap(\.id)
            let tagLinks = try TagToTransactionDB.filter(transactionIDs.contains(TagToTransactionDB.Columns.transactionId)).fetchAll(db)
            let tagIDsNeeded = Set(tagLinks.map(\.tagId))
            let tagsDB = try TagDB.filter(tagIDsNeeded.contains(TagDB.Columns.id)).fetchAll(db)
            let tagNameMap = Dictionary(uniqueKeysWithValues: tagsDB.compactMap { tag -> (UUID, String)? in
                guard let id = tag.id else { return nil }
                return (id, tag.name)
            })
            var tagNamesByTransaction: [UUID: [String]] = [:]
            for link in tagLinks {
                tagNamesByTransaction[link.transactionId, default: []].append(tagNameMap[link.tagId] ?? "")
            }

            return transactionsDB.compactMap { t -> TransactionListRowData? in
                guard let id = t.id,
                      let accountFrom = accountMap[t.accountFromId],
                      let accountTo = accountMap[t.accountToId],
                      let accountFromCurrency = currencyMap[accountFrom.currencyCode],
                      let accountToCurrency = currencyMap[accountTo.currencyCode]
                else { return nil }

                return TransactionListRowData(
                    id: id,
                    dateTransaction: t.dateTransaction,
                    type: t.type,
                    accountFromName: accountFrom.name,
                    accountFromType: accountFrom.type,
                    accountFromCurrency: accountFromCurrency,
                    accountToName: accountTo.name,
                    accountToCurrency: accountToCurrency,
                    amountFrom: t.amountFrom,
                    amountTo: t.amountTo,
                    note: t.note,
                    tagNames: tagNamesByTransaction[id] ?? []
                )
            }
        }
    }

    // Отдельный лёгкий запрос только за датами (для горизонтального календаря над списком
    // транзакций) — без него список дней зависел бы от того, сколько страниц транзакций уже
    // подгружено пагинацией, и календарь показывал бы не всю историю, а только загруженный
    // хвост.
    func getTransactionDays(
        dateFrom: Date? = nil,
        dateTo: Date? = nil,
        searchText: String = "",
        accountIDs: [UUID] = [],
        excludedAccountIDs: [UUID] = [],
        accountGroupIDs: [UUID] = [],
        transactionTypes: [TransactionType] = [],
        currencies: [Currency] = [],
        tagIDs: [UUID] = [],
        excludedTagIDs: [UUID] = []
    ) async throws -> [Date] {
        try await sqlite.read { db in

            var joins: [String] = []
            var filters: [String] = []
            var args: StatementArguments = []

            if let dateFrom {
                filters.append("t.dateTransaction >= ?")
                _ = args.append(contentsOf: [dateFrom])
            }

            if let dateTo {
                filters.append("t.dateTransaction <= ?")
                _ = args.append(contentsOf: [dateTo])
            }

            if searchText != "" {
                filters.append("lowerUnicode(t.note) LIKE lowerUnicode(?)")
                _ = args.append(contentsOf: ["%"+searchText+"%"])
            }

            if !accountIDs.isEmpty {
                var questions: [String] = []
                for _ in accountIDs {
                    questions.append("?")
                }

                filters.append("(t.accountFromId IN (\(questions.joined(separator: ","))) OR t.accountToId IN (\(questions.joined(separator: ","))))")
                _ = args.append(contentsOf: StatementArguments(accountIDs))
                _ = args.append(contentsOf: StatementArguments(accountIDs))
            }

            if !excludedAccountIDs.isEmpty {
                var questions: [String] = []
                for _ in excludedAccountIDs {
                    questions.append("?")
                }

                filters.append("(t.accountFromId NOT IN (\(questions.joined(separator: ","))) AND t.accountToId NOT IN (\(questions.joined(separator: ","))))")
                _ = args.append(contentsOf: StatementArguments(excludedAccountIDs))
                _ = args.append(contentsOf: StatementArguments(excludedAccountIDs))
            }

            if !accountGroupIDs.isEmpty {
                var questions: [String] = []
                for _ in accountGroupIDs {
                    questions.append("?")
                }

                filters.append("t.accountGroupId IN (\(questions.joined(separator: ",")))")
                _ = args.append(contentsOf: StatementArguments(accountGroupIDs))
            }

            if !tagIDs.isEmpty {
                var questions: [String] = []
                for _ in tagIDs {
                    questions.append("?")
                }

                joins.append("JOIN tagToTransactionDB tttd ON tttd.transactionId = t.id")
                joins.append("JOIN tagDB tg ON tttd.tagId = tg.id")

                filters.append("tg.id IN (\(questions.joined(separator: ",")))")
                _ = args.append(contentsOf: StatementArguments(tagIDs))
            }

            if !excludedTagIDs.isEmpty {
                var questions: [String] = []
                for _ in excludedTagIDs {
                    questions.append("?")
                }
                filters.append("""
                    NOT EXISTS (
                        SELECT 1 FROM tagToTransactionDB ex_tttd
                        WHERE ex_tttd.transactionId = t.id AND ex_tttd.tagId IN (\(questions.joined(separator: ",")))
                    )
                    """)
                _ = args.append(contentsOf: StatementArguments(excludedTagIDs))
            }

            if !transactionTypes.isEmpty {
                var questions: [String] = []
                for _ in transactionTypes {
                    questions.append("?")
                }

                filters.append("t.type IN (\(questions.joined(separator: ",")))")
                _ = args.append(contentsOf: StatementArguments(transactionTypes.map(\.rawValue)))
            }

            if !currencies.isEmpty {
                var questions: [String] = []
                for _ in currencies {
                    questions.append("?")
                }

                joins.append("JOIN accountDB a1 ON a1.id = t.accountFromId")
                joins.append("JOIN accountDB a2 ON a2.id = t.accountToId")

                filters.append("(a1.currencyCode IN (\(questions.joined(separator: ","))) OR a2.currencyCode IN (\(questions.joined(separator: ","))))")
                _ = args.append(contentsOf: StatementArguments(currencies.map(\.code)))
                _ = args.append(contentsOf: StatementArguments(currencies.map(\.code)))
            }

            let sql = """
                SELECT DISTINCT t.dateTransaction
                FROM transactionDB t
                \(joins.joined(separator: "\n"))
                \(filters.isEmpty ? "" : "WHERE \(filters.joined(separator: "\nAND "))")
                ORDER BY t.dateTransaction ASC
            """

            return try Date.fetchAll(db, sql: sql, arguments: args)
        }
    }

    func getStatisticByMonth(
        chartType: ChartType,
        groupBy: ChartViewGroupBy,
        period: ChartPeriod = .month,
        transactionType: TransactionType,
        accountGroupIDs: [UUID],
        targetCurrency: Currency,
        accountParameterIgnore: Bool = false,
        transactionParameterIgnore: Bool = false,
        accountIDs: [UUID] = [],
        excludedAccountIDs: [UUID] = [],
        dateFrom: Date? = nil,
        dateTo: Date? = nil,
        tagIDs: [UUID] = [],
        excludedTagIDs: [UUID] = [],
        currencies: [Currency] = [],
        searchText: String = ""
    ) async throws -> [Series] {
        try await sqlite.read { db in
            
            var selects: [String] = [
                "\(period.sqlStartOf("t.dateTransaction")) AS month",
                "ROUND(SUM(t.\(transactionType == .consumption ? "amountTo" : "amountFrom") * ((SELECT rate FROM currencyDB WHERE code = '\(targetCurrency.code)') / (SELECT rate FROM currencyDB WHERE code = a.currencyCode)))) AS remainder"
            ]
            var joins: [String] = [
                "JOIN accountDB a ON a.id = t.\(transactionType == .consumption ? "accountToId" : "accountFromId")"
            ]
            var filters: [String] = [
                "a.type = ?"
            ]
            var args: StatementArguments = [
                "\(transactionType == .consumption ? "expense" : "earnings")"
            ]
            var groups: [String] = [
                "month"
            ]
                       
            var tagJoined = false
            if chartType == .expenses || chartType == .earnings {
                switch groupBy {
                case .byAccount:
                    selects.append("a.id AS accountId")
                    groups.append("accountId")
                case .byTag:
                    selects.append("tg.id as tagId")
                    joins.append("JOIN tagToTransactionDB tttd ON tttd.transactionId = t.id")
                    joins.append("JOIN tagDB tg ON tttd.tagId = tg.id")
                    groups.append("tagId")
                    tagJoined = true
                }
            }

            // Опциональные фильтры
            if !accountParameterIgnore {
                filters.append("a.accountingInCharts = ?")
                _ = args.append(contentsOf: [true])
            }
            if !transactionParameterIgnore {
                filters.append("t.accountingInCharts = ?")
                _ = args.append(contentsOf: [true])
            }
            if !accountIDs.isEmpty {
                var questions: [String] = []
                for _ in accountIDs {
                    questions.append("?")
                }
                filters.append("a.id in (\(questions.joined(separator: ", ")))")
                _ = args.append(contentsOf: StatementArguments(accountIDs))
            }
            if !excludedAccountIDs.isEmpty {
                var questions: [String] = []
                for _ in excludedAccountIDs {
                    questions.append("?")
                }
                filters.append("a.id not in (\(questions.joined(separator: ", ")))")
                _ = args.append(contentsOf: StatementArguments(excludedAccountIDs))
            }
            if !accountGroupIDs.isEmpty {
                var questions: [String] = []
                for accountGroupID in accountGroupIDs {
                    questions.append("?")
                    _ = args.append(contentsOf: [accountGroupID])
                }
                filters.append("t.accountGroupId in (\(questions.joined(separator: ", ")))")
            }
            if let dateFrom {
                filters.append("t.dateTransaction >= ?")
                _ = args.append(contentsOf: [dateFrom])
            }
            if let dateTo {
                filters.append("t.dateTransaction <= ?")
                _ = args.append(contentsOf: [dateTo])
            }
            if !tagIDs.isEmpty {
                var questions: [String] = []
                for _ in tagIDs {
                    questions.append("?")
                }
                if !tagJoined {
                    joins.append("JOIN tagToTransactionDB tttd ON tttd.transactionId = t.id")
                    joins.append("JOIN tagDB tg ON tttd.tagId = tg.id")
                }
                filters.append("tg.id in (\(questions.joined(separator: ", ")))")
                _ = args.append(contentsOf: StatementArguments(tagIDs))
            }
            if !excludedTagIDs.isEmpty {
                var questions: [String] = []
                for _ in excludedTagIDs {
                    questions.append("?")
                }
                // Отдельный алиас (ex_tttd) — не переиспользует tttd/tg, который может быть уже
                // занят JOIN'ом от byTag/tagIDs выше, и NOT EXISTS (не JOIN+NOT IN), т.к. у
                // транзакции может быть несколько тегов сразу.
                filters.append("""
                    NOT EXISTS (
                        SELECT 1 FROM tagToTransactionDB ex_tttd
                        WHERE ex_tttd.transactionId = t.id AND ex_tttd.tagId IN (\(questions.joined(separator: ", ")))
                    )
                    """)
                _ = args.append(contentsOf: StatementArguments(excludedTagIDs))
            }
            if !currencies.isEmpty {
                var questions: [String] = []
                for _ in currencies {
                    questions.append("?")
                }
                filters.append("a.currencyCode in (\(questions.joined(separator: ", ")))")
                _ = args.append(contentsOf: StatementArguments(currencies.map(\.code)))
            }
            if searchText != "" {
                filters.append("lowerUnicode(t.note) LIKE lowerUnicode(?)")
                _ = args.append(contentsOf: ["%"+searchText+"%"])
            }

            // Мапа ObjectID - Дата - Сумма
            var result: [UUID: [Date: Decimal]] = [:]
            
            let sql = """
                SELECT \(selects.joined(separator: ",\n"))
                FROM transactionDB t
                \(joins.joined(separator: "\n"))
                WHERE \(filters.joined(separator: "\nAND "))
                GROUP BY \(groups.joined(separator: ", "))
            """
            
            print(sql)
            print(args)
            
            let rows = try Row.fetchCursor(db, sql: sql, arguments: args)
            
            while let row = try rows.next() {
                switch chartType {
                case .earningsAndExpenses:
                    if result[UUID(uuid: UUID_NULL)] == nil {
                        result[UUID(uuid: UUID_NULL)] = [:]
                    }
                    result[UUID(uuid: UUID_NULL)]?[row["month"]] = row["remainder"]
                case .expenses, .earnings:
                    switch groupBy {
                    case .byTag:
                        let tagID: UUID = row["tagId"]
                        if result[tagID] == nil {
                            result[tagID] = [:]
                        }
                        result[tagID]?[row["month"]] = row["remainder"]
                    case .byAccount:
                        let accountID: UUID = row["accountId"]
                        if result[accountID] == nil {
                            result[accountID] = [:]
                        }
                        result[accountID]?[row["month"]] = row["remainder"]
                    }
                case .balance, .balanceTotal, .delta:
                    break // Баланс обрабатывается отдельно через getMonthlyNetFlowByAccount; дельта сюда не заходит (передаётся .earningsAndExpenses)
                }
            }
            
            return result.map { (categoryName: UUID, monthData: [Date : Decimal]) in
                Series(
                    account: nil,
                    tag: nil,
                    type: nil,
                    objectID: categoryName,
                    data: monthData
                )
            }
        }
    }
    
    // Возвращает чистый поток по периодам для счетов типа regular/debt
    // Положительное значение = деньги поступили, отрицательное = ушли
    func getMonthlyNetFlowByAccount(
        period: ChartPeriod = .month,
        targetCurrency: Currency,
        accountGroupIDs: [UUID] = [],
        accountIDs: [UUID] = []
    ) async throws -> [UUID: [Date: Decimal]] {
        try await sqlite.read { db in
            var result: [UUID: [Date: Decimal]] = [:]
            
            // Строим фильтры общие для обоих запросов
            func buildFiltersAndArgs(accountIDField: String) -> ([String], StatementArguments) {
                var filters: [String] = [
                    "a.type IN ('regular', 'debt')",
                    "a.accountingInCharts = 1",
                    "t.accountingInCharts = 1"
                ]
                var args: StatementArguments = []
                if !accountIDs.isEmpty {
                    let q = accountIDs.map { _ in "?" }.joined(separator: ", ")
                    filters.append("a.id IN (\(q))")
                    _ = args.append(contentsOf: StatementArguments(accountIDs))
                }
                if !accountGroupIDs.isEmpty {
                    let q = accountGroupIDs.map { _ in "?" }.joined(separator: ", ")
                    filters.append("t.accountGroupId IN (\(q))")
                    _ = args.append(contentsOf: StatementArguments(accountGroupIDs))
                }
                return (filters, args)
            }
            
            let periodExpr = period.sqlStartOf("t.dateTransaction")
            
            // Деньги, поступающие на счёт (accountToId)
            let (inFilters, inArgs) = buildFiltersAndArgs(accountIDField: "accountToId")
            let inSQL = """
                SELECT \(periodExpr) AS month,
                    a.id AS accountId,
                    ROUND(SUM(t.amountTo * ((SELECT rate FROM currencyDB WHERE code = '\(targetCurrency.code)') / (SELECT rate FROM currencyDB WHERE code = a.currencyCode)))) AS amount
                FROM transactionDB t
                JOIN accountDB a ON a.id = t.accountToId
                WHERE \(inFilters.joined(separator: " AND "))
                GROUP BY month, accountId
            """
            let inRows = try Row.fetchCursor(db, sql: inSQL, arguments: inArgs)
            while let row = try inRows.next() {
                let accountID: UUID = row["accountId"]
                let month: Date = row["month"]
                let amount: Decimal = row["amount"]
                if result[accountID] == nil { result[accountID] = [:] }
                result[accountID]![month, default: 0] += amount
            }
            
            // Деньги, уходящие со счёта (accountFromId)
            let (outFilters, outArgs) = buildFiltersAndArgs(accountIDField: "accountFromId")
            let outSQL = """
                SELECT \(periodExpr) AS month,
                    a.id AS accountId,
                    ROUND(SUM(t.amountFrom * ((SELECT rate FROM currencyDB WHERE code = '\(targetCurrency.code)') / (SELECT rate FROM currencyDB WHERE code = a.currencyCode)))) AS amount
                FROM transactionDB t
                JOIN accountDB a ON a.id = t.accountFromId
                WHERE \(outFilters.joined(separator: " AND "))
                GROUP BY month, accountId
            """
            let outRows = try Row.fetchCursor(db, sql: outSQL, arguments: outArgs)
            while let row = try outRows.next() {
                let accountID: UUID = row["accountId"]
                let month: Date = row["month"]
                let amount: Decimal = row["amount"]
                if result[accountID] == nil { result[accountID] = [:] }
                result[accountID]![month, default: 0] -= amount
            }
            
            return result
        }
    }
    
    func createTask(_ task: SyncTask) async throws {
        try await sqlite.write { db in
            try SyncTaskDB(task).insert(db)
        }
    }
    
    func updateTask(_ task: SyncTask) async throws {
        try await sqlite.write { db in
            _ = try SyncTaskDB(task).update(db)
        }
    }
}

enum ModelType: String, Codable {
    case account, transaction, tag, icon, user, accountGroup
}
