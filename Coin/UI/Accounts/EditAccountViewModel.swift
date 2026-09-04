//
//  EditAccountViewModel.swift
//  Coin
//
//  Created by Илья on 26.03.2024.
//

import Foundation
import Factory


enum mode {
    case create, update
}

@Observable
class EditAccountViewModel {
    @ObservationIgnored
    @Injected(\.service) private var service
    
    var currencies: [Currency] = []
    var icons: [Icon] = []
    var accountGroups: [AccountGroup] = []
    var accounts: [Account] = []
    var linkableAccounts: [Account] = []
    
    var currentAccount = Account()
    @ObservationIgnored private var hasLoadedDefaults = false
    var remainder: Double {
        didSet {
            currentAccount.remainder = Decimal(floatLiteral: remainder)
        }
    }
    var budgetAmount: Double {
        didSet {
            currentAccount.budgetAmount = Decimal(floatLiteral: budgetAmount)
        }
    }
    var budgetFixedSum: Double {
        didSet {
            currentAccount.budgetFixedSum = Decimal(floatLiteral: budgetFixedSum)
        }
    }
    var oldAccount = Account()
    
    var mode: mode
    var isHiddenView: Bool
    
    init(
        currentAccount: Account,
        oldAccount: Account = Account(),
        mode: mode,
        isHiddenView: Bool = false
    ) {
        self.currentAccount = currentAccount
        self.oldAccount = oldAccount
        self.mode = mode
        self.isHiddenView = isHiddenView
        self.budgetAmount = currentAccount.budgetAmount.doubleValue
        self.budgetFixedSum = currentAccount.budgetFixedSum.doubleValue
        self.remainder = currentAccount.remainder.doubleValue
    }
    
    var isChanged: Bool {
        mode == .update ? currentAccount != oldAccount : true
    }

    var permissions: AccountPermissions {
        GetPermissions(account: currentAccount)
    }
        
    func load(accountGroup: AccountGroup) async throws {
        currencies = try await service.getCurrencies()
        accountGroups = try await service.getAccountGroups()
        icons = try await service.getIcons()
        var visible: Bool? = nil
        if !isHiddenView {
            visible = true
        }
        accounts = try await service.getAccounts(visible: visible, types: [currentAccount.type])

        // Кандидаты для связи "счёт-мост" — счёт совместимого типа (см. bridgeCompatibleType),
        // той же валюты, ещё не связанный ни с чем, из ЛЮБОЙ моей группы (не только текущей —
        // весь смысл моста в том, чтобы соединять счета из разных групп) и не сам currentAccount.
        if mode == .update, let compatibleType = Self.bridgeCompatibleType(for: currentAccount.type) {
            let candidates = try await service.getAccounts(types: [compatibleType], currencyCode: currentAccount.currency.code)
                .filter { $0.id != currentAccount.id && $0.linkedAccountID == nil }

            // Родительский счёт хранит СВОЮ валюту (обычно валюту группы по умолчанию), которая
            // может отличаться от валюты конкретного дочернего счёта — если фильтровать
            // родителей по той же валюте, что и детей, подходящий ребёнок остаётся без узла
            // родителя в пикере и становится недостижим. Поэтому родителей кандидатов
            // подгружаем отдельно, без фильтра по валюте.
            let parentIDs = Set(candidates.compactMap(\.parentAccountID))
            let parents = parentIDs.isEmpty ? [] : try await service.getAccounts(ids: Array(parentIDs))

            linkableAccounts = candidates + parents.filter { parent in !candidates.contains { $0.id == parent.id } }
        } else {
            linkableAccounts = []
        }

        // Валюту/иконку по умолчанию проставляем только при первой загрузке — иначе load()
        // (который заново вызывается из .task при каждом возврате с других экранов формы,
        // например из CurrencyPicker) стирал бы уже выбранную пользователем валюту.
        if mode == .create && !hasLoadedDefaults {
            currentAccount.currency = currencies.first(where: { accountGroup.currency.code == $0.code }) ?? currencies.first ?? Currency()

            if let icon = icons.first {
                currentAccount.icon = icon
            }
        }
        hasLoadedDefaults = true
    }
    
    func createAccount() async throws {
        try await service.createAccount(currentAccount)
    }
    
    func updateAccount() async throws {
        try await service.updateAccount(newAccount: currentAccount, oldAccount: oldAccount)
    }
    
    func deleteAccount() async throws {
        try await service.deleteAccount(currentAccount)
    }

    /// Разрешённые пары типов для счёта-моста: regular↔regular, expense↔earnings.
    static func bridgeCompatibleType(for type: AccountType) -> AccountType? {
        switch type {
        case .regular: return .regular
        case .expense: return .earnings
        case .earnings: return .expense
        default: return nil
        }
    }
}
