//
//  TransactionsView.swift
//  Coin
//
//  Created by Илья on 17.04.2024.
//

import SwiftUI

struct TransactionFilters: Equatable, Hashable {
    var searchText = ""
    var dateFrom: Date?
    var dateTo: Date?
    var transactionTypes: [TransactionType] = []
    var currencies: [Currency] = []
    var accounts: [Account] = []
    // Счета (и их дочерние счета), транзакции по которым нужно скрыть из выборки.
    var excludedAccounts: [Account] = []
    var tags: [Tag] = []
    // Теги, транзакции с которыми нужно скрыть из выборки (аналог excludedAccounts, но для тегов).
    var excludedTags: [Tag] = []
    var accountGroups: [AccountGroup]
}
