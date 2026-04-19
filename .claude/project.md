# Coin — iOS Personal Finance App

## Overview
iOS app for personal finance management (expenses, income, transfers, budgets, charts).
Language: Swift/SwiftUI. Target: iOS.

## Architecture (top-down)

### UI Layer — `Coin/Coin/UI/`
SwiftUI views + `@Observable` ViewModels (MVVM).
Navigation via `AppTabView` with tabs:
- AccountHomeTab → AccountsHomeView (balances, budgets)
- AccountCirclesTab → AccountCirclesView (drag-and-drop circles)
- TransactionsTab → TransactionsView (list + chart + search)
- ProfileTab → Profile (settings, currency converter, tasks list)
- DeveloperToolsTab — dev tools (sync check, reset DB)

### Service Layer — `Coin/Coin/Service/`
`Service` — singleton injected via **Factory** DI (`Container.service`).
Split into extensions per domain:
- `TransactionService.swift` — CRUD for transactions
- `AccountService.swift` — CRUD for accounts + balance recalculation
- `AccountGroupService.swift` — account groups
- `TagService.swift` — tags
- `UserService.swift`, `SettingsService.swift`, `AuthService.swift`

`TaskManager` — offline-first sync queue. Saves `SyncTask` to SQLite, then executes against API (gRPC).

### Repository Layer — `Coin/Coin/Repository/`
`Repository` → `SQLite` (GRDB library, DatabasePool).
DB file: `ApplicationSupport/database/db.sqlite`.
Migrations in `SQLite/Migrator.swift`.

DB models (`*DB` structs) in `Repository/Model/`:
- `TransactionDB`, `AccountDB`, `AccountGroupDB`, `TagDB`
- `TagToTransactionDB` — M2M join table
- `CurrencyDB`, `IconDB`, `UserDB`, `SyncTaskDB`

### Network Layer — `Coin/Coin/Network/`
`APIManager` — facade over gRPC clients.
Protocol: **gRPC + Protobuf** via `GRPCCore` + `GRPCNIOTransportHTTP2`.
Proto definitions: `ProtoDefinitions` Swift package.
Server: `127.0.0.1:8090` plaintext (local dev).

Endpoints (gRPC clients):
- `Transaction_TransactionEndpoint`
- `Account_AccountEndpoint`
- `AccountGroup_AccountGroupEndpoint`
- `Auth_AuthEndpoint`
- `Settings_SettingsEndpoint`
- `Tag_TagEndpoint`
- `User_UserEndpoint`

`AuthManager` — manages JWT access tokens (auto-refresh).
`NetworkManager` — legacy HTTP JSON client (still used for some endpoints like GetIcon image download).

### Models — `Coin/Coin/Model/`
Business models (UI-facing):
- `Transaction` — id:UUID, amountFrom/To:Decimal, type:TransactionType, accountFrom/To:Account, tags:[Tag]
- `Account` — id:UUID, type:AccountType, remainder:Decimal, isParent:Bool, childrenAccounts:[Account], currency:Currency
- `AccountGroup`, `Tag`, `Currency`, `Icon`, `User`, `SyncTask`

`TransactionType`: consumption, income, transfer, balancing
`AccountType`: expense, earnings, debt, regular, balancing

## Data Flow (happy path)
1. ViewModel calls `service.createTransaction(_:)`
2. Service validates, writes to `repository` (SQLite) immediately
3. Service calls `repository.recalculateAccountBalances()`
4. Service calls `taskManager.createTask(actionName: .createTransaction, reqModel: ...)`
5. TaskManager serializes req to JSON, saves `SyncTask` to SQLite
6. TaskManager.executeDBTasks() picks up tasks and calls `apiManager.CreateTransaction(req:)`

## DI
Factory framework. Main container in `CoinApp.swift`:
```swift
Container.service → Service(repository:apiManager:taskManager:authManager:)
```
ViewModels inject service via `@Injected(\.service)`.

## Key Conventions
- IDs are `UUID` (branch `feat/move-to-uuid` migrates from Int to UUID)
- Amounts use `Decimal` (rounded to 7 decimal places via `round(factor:)`)
- Dates stored stripped of time for transactions (`stripTime()` in `Pkg/StripTime.swift`)
- Offline-first: all mutations go to SQLite first, API sync is async via TaskManager
- `@Observable` for ViewModels and Service (no Combine)
- AlertManager passed via SwiftUI `.environment()` for error display

## File Map (key paths)
```
Coin/Coin/
  CoinApp.swift              — App entry, DI container setup
  Service/
    Service.swift            — Core service class + sync/stats logic
    TransactionService.swift
    AccountService.swift
    TaskManager/TaskManager.swift
  Repository/
    Repository.swift         — All DB queries
    SQLite/SQLite.swift      — GRDB setup + migrations trigger
    SQLite/Migrator.swift    — DB migrations
    Model/                   — *DB structs (GRDB FetchableRecord/PersistableRecord)
  Network/
    APIManager.swift         — gRPC clients facade
    NetworkManager/          — HTTP JSON client (legacy)
    AuthManager/AuthManager.swift
    Model/                   — Request/Response structs
  Model/                     — Business models (UI-facing)
  UI/                        — SwiftUI views + ViewModels
  Pkg/                       — Utilities (date helpers, formatters, JWT checker)
```

## Current Branch: feat/move-to-uuid
Migrating entity IDs from Int/String to UUID across:
- `TransactionModels.swift`, `TransactionAPI.swift`
- `AccountDB.swift`, `TransactionDB.swift`
- `Migrator.swift` (new migration)
- `Service.swift`, `TransactionService.swift`
