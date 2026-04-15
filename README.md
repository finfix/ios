# Coin — iOS-приложение для учёта личных финансов

## О проекте

Coin — мобильное приложение для iOS, которое помогает вести учёт доходов, расходов, переводов и балансировок по нескольким счетам и группам счетов. Поддерживает бюджеты, теги, графики, несколько валют и офлайн-режим с последующей синхронизацией.

---

## Стек технологий

| Область | Технологии |
|---|---|
| Язык / UI | Swift 5.9+, SwiftUI, `@Observable` |
| Локальная БД | GRDB (SQLite, DatabasePool) |
| Сеть | gRPC (GRPCCore + GRPCNIOTransportHTTP2 + Protobuf) |
| DI | Factory |
| Логирование | OSLog |
| Прочее | DeviceKit, UserNotifications |

---

## Архитектура

Приложение построено по многослойной архитектуре: **UI → Service → Repository → SQLite** и параллельно **Service → TaskManager → APIManager → gRPC-сервер**.

```
CoinApp.swift (точка входа, DI-контейнер)
│
├── UI Layer (SwiftUI Views + @Observable ViewModels)
│
├── Service Layer
│   ├── Service.swift                  — центральный сервис
│   ├── TransactionService.swift       — CRUD транзакций
│   ├── AccountService.swift           — CRUD счетов + пересчёт балансов
│   ├── AccountGroupService.swift
│   ├── TagService.swift
│   ├── UserService.swift
│   ├── SettingsService.swift
│   ├── AuthService.swift
│   └── TaskManager/TaskManager.swift  — очередь офлайн-задач
│
├── Repository Layer
│   ├── Repository.swift               — все запросы к БД
│   ├── SQLite/SQLite.swift            — инициализация GRDB
│   ├── SQLite/Migrator.swift          — миграции схемы БД
│   └── Model/*DB.swift                — модели для GRDB
│
└── Network Layer
    ├── APIManager.swift               — фасад над gRPC-клиентами
    ├── NetworkManager/                — HTTP JSON-клиент (legacy, иконки)
    ├── AuthManager/AuthManager.swift  — JWT-токены, автообновление
    └── Model/                         — Request/Response-структуры
```

---

## Слои подробно

### UI Layer — `Coin/Coin/UI/`

Навигация через `AppTabView` (tab bar с 5 вкладками):

- **AccountHomeTab** — главный экран с балансами и бюджетами счетов, сгруппированных по типу (расходы, доходы, долги, обычные)
- **AccountCirclesTab** — визуальный режим счетов в виде кружков с drag-and-drop переупорядочиванием
- **TransactionsTab** — список транзакций, поиск, фильтры (по счёту, типу, валюте, тегу, диапазону дат), графики доходов/расходов
- **ProfileTab** — настройки пользователя, конвертер валют, список фоновых задач, скрытые счета
- **DeveloperToolsTab** — инструменты разработчика: сверка локальных и серверных данных, сброс БД

Каждый экран имеет пару `View` + `ViewModel`. ViewModel — `@Observable`-класс, инжектирует `Service` через `@Injected(\.service)`.

Ошибки показываются через `AlertManager`, передаваемый через `.environment()`.

### Service Layer — `Coin/Coin/Service/`

`Service` — синглтон (Factory), основная точка входа для всей бизнес-логики. Разделён на extensions по доменам:

**TransactionService:**
- `createTransaction` — валидация → запись в SQLite → пересчёт балансов счетов → создание задачи в TaskManager
- `updateTransaction` — дифференциальное обновление (в API передаются только изменённые поля)
- `deleteTransaction` — удаление + пересчёт балансов
- `getTransactions` — с фильтрами: дата, счёт, тип, валюта, теги, группа счетов

**AccountService:**
- `createAccount` — если у счёта ненулевой начальный баланс, автоматически создаётся балансировочная транзакция
- `updateAccount` — синхронизирует видимость и `accountingInHeader` между родительским и дочерними счетами; управляет порядковым номером
- `recalculateAccountBalances` — пересчитывает остатки счетов из транзакций (для expense/earnings/balancing — за текущий месяц; для regular/debt — за всё время)

**TaskManager:**
- Сохраняет каждую мутацию как `SyncTask` в SQLite (JSON-сериализованный запрос)
- `executeDBTasks` запускается по таймеру каждые 15 секунд, выполняет задачи последовательно, удаляет выполненные
- При ошибке API инкрементирует `tryCount` у задачи и сохраняет текст ошибки

### Repository Layer — `Coin/Coin/Repository/`

`Repository` — тонкая обёртка над `SQLite` (GRDB `DatabasePool`). Все операции асинхронные.

**Таблицы БД:**

| Таблица | Назначение |
|---|---|
| `currencyDB` | Валюты (code, name, rate, symbol) |
| `userDB` | Данные пользователя |
| `accountGroupDB` | Группы счетов |
| `iconDB` | Иконки счетов (url на локальный файл) |
| `accountDB` | Счета, включая иерархию parent/child |
| `transactionDB` | Транзакции |
| `tagDB` | Теги |
| `tagToTransactionDB` | M2M: теги ↔ транзакции |
| `syncTaskDB` | Очередь офлайн-задач |

Файл БД: `ApplicationSupport/database/db.sqlite`.  
Запуск с аргументом `-reset` удаляет папку с БД.  
В DEV-сборке (`#if DEV`) включён `eraseDatabaseOnSchemaChange`.

### Network Layer — `Coin/Coin/Network/`

**APIManager** — фасад над семью gRPC-клиентами:
- `Transaction_TransactionEndpoint`
- `Account_AccountEndpoint`
- `AccountGroup_AccountGroupEndpoint`
- `Auth_AuthEndpoint`
- `Settings_SettingsEndpoint`
- `Tag_TagEndpoint`
- `User_UserEndpoint`

Сервер: `127.0.0.1:8090` plaintext (локальная разработка).  
Proto-определения: Swift Package `ProtoDefinitions`.

**AuthManager** — JWT-токены хранятся в `@AppStorage`. При истечении access-токена автоматически обновляет через gRPC `refreshTokens`. При невозможности обновить — разлогинивает.

**NetworkManager** — legacy HTTP/JSON-клиент, используется для скачивания бинарных данных (иконки).

---

## Ключевые модели

### Бизнес-модели (`Coin/Coin/Model/`)

**Transaction**
```swift
id: UUID
type: TransactionType          // consumption, income, transfer, balancing
amountFrom / amountTo: Decimal // суммы в разных валютах
accountFrom / accountTo: Account
dateTransaction: Date          // хранится без времени (stripTime)
tags: [Tag]
accountingInCharts: Bool
accountGroupID: UUID
```

**Account**
```swift
id: UUID
type: AccountType              // expense, earnings, debt, regular, balancing
remainder: Decimal             // текущий остаток
budgetAmount: Decimal          // бюджет на месяц
isParent: Bool                 // родительский счёт (агрегирует дочерние)
parentAccountID: UUID?
childrenAccounts: [Account]    // дочерние счета
currency: Currency
accountGroup: AccountGroup
```

**Типы транзакций:** `consumption` (расход), `income` (доход), `transfer` (перевод между счетами), `balancing` (корректировка баланса)

**Типы счетов:** `expense` (расходные), `earnings` (доходные), `debt` (долги), `regular` (обычные накопительные), `balancing` (технические балансировочные)

### Офлайн-синхронизация

```
Пользователь → Service.createTransaction()
  → repository.createTransaction()           // 1. Записываем в SQLite
  → repository.recalculateAccountBalances()  // 2. Пересчитываем балансы
  → taskManager.createTask(.createTransaction, req) // 3. Ставим в очередь
    → repository.createTask(SyncTask(...))   // Сохраняем задачу в SQLite

Таймер каждые 15 сек → taskManager.executeDBTasks()
  → apiManager.CreateTransaction(req)        // gRPC-вызов
  → repository.deleteTasks([task.id])        // Удаляем выполненную задачу
```

---

## DI (Factory)

Основной контейнер объявлен в `CoinApp.swift`:

```swift
Container.service → Service(
    repository: Repository(sqlite: SQLite()),
    apiManager: APIManager(networkManager:authClient:transactionClient:...),
    taskManager: TaskManager(repository:apiManager:),
    authManager: AuthManager(authClient:)
)
```

ViewModels получают сервис через `@Injected(\.service)`.

---

## Соглашения по коду

- **Идентификаторы** — `UUID` (ветка `feat/move-to-uuid` завершает миграцию с Int)
- **Суммы** — `Decimal`, округляются до 7 знаков (`round(factor: 7)`)
- **Даты транзакций** — хранятся без времени суток (`stripTime()`)
- **Реактивность** — `@Observable` + async/await; Combine не используется
- **Ошибки** — `ErrorModel` с полем `humanText` для отображения пользователю
- **Балансы** — expense/earnings/balancing считаются за текущий месяц; regular/debt — за всё время
- **Комментарии и названия переменных** — на русском языке

---

## Запуск

1. Запустить backend-сервер на `127.0.0.1:8090` (gRPC plaintext)
2. Открыть `Coin.xcodeproj` в Xcode
3. Запустить на симуляторе или устройстве
4. Для сброса БД добавить аргумент запуска `-reset`
