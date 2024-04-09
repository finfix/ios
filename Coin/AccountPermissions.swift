//
//  AccountPermissions.swift
//  Coin
//
//  Created by Илья on 21.03.2024.
//

import Foundation

struct AccountPermissions {
    var changeBudget: Bool = true
    var changeRemainder: Bool = true
    var changeCurrency: Bool = true
    var changeParentAccountID: Bool = true
    var linkToParentAccount: Bool = true
}

private let typeToPermissions: [AccountType: AccountPermissions] = [
    // Запреты для счетов долгов - нельзя менять только бюджеты
    .debt: AccountPermissions(
        changeBudget: false
    ),
    // Запреты для счетов доходов - нельзя менять только остатки счетов
    .earnings: AccountPermissions(
        changeRemainder: false
    ),
    // Запреты для обычных счетов - нельзя менять только бюджеты
    .regular: AccountPermissions(
        changeBudget: false
    ),
    // Запреты для счетов расходов - нельзя менять только остатки счетов
    .expense: AccountPermissions(
        changeRemainder: false
    )
]

private let isParentToPermissions: [Bool: AccountPermissions] = [
    // Запреты для дочерних счетов - нельзя менять валюту
    false: AccountPermissions(
        changeCurrency: false
    ),
    // Запреты для родительских счетов - нельзя менять остатки счетов и привязывать к родительским счетам
    true: AccountPermissions(
        changeRemainder: false,
        changeParentAccountID: false,
        linkToParentAccount: false
    )
]

func GetPermissions(account: Account) -> AccountPermissions {
    return joinPermissions(permissions: [
        typeToPermissions[account.type]!,
        isParentToPermissions[account.isParent]!
    ])
}

private func joinPermissions(permissions: [AccountPermissions]) -> AccountPermissions {
    var joinedPermissions = AccountPermissions()
    for permission in permissions {
        joinedPermissions.changeBudget = joinedPermissions.changeBudget && permission.changeBudget
        joinedPermissions.changeRemainder = joinedPermissions.changeRemainder && permission.changeRemainder
        joinedPermissions.changeCurrency = joinedPermissions.changeCurrency && permission.changeCurrency
        joinedPermissions.changeParentAccountID = joinedPermissions.changeParentAccountID && permission.changeParentAccountID
        joinedPermissions.linkToParentAccount = joinedPermissions.linkToParentAccount && permission.linkToParentAccount
    }
    return joinedPermissions
}
