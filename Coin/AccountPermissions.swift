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
    var linkToParentAccount: Bool = true
}

private let typeToPermissions: [AccountType: AccountPermissions] = [
    // Разрешения для счетов долгов - нельзя менять только бюджеты
    .debt: AccountPermissions(
        changeBudget: false,
        changeRemainder: true,
        linkToParentAccount: true
    ),
    // Разрешения для счетов доходов - нельзя менять только остатки счетов
    .earnings: AccountPermissions(
        changeBudget: true,
        changeRemainder: false,
        linkToParentAccount: true
    ),
    // Разрешения для обычных счетов - нельзя менять только бюджеты
    .regular: AccountPermissions(
        changeBudget: false,
        changeRemainder: true,
        linkToParentAccount: true
    ),
    // Разрешения для счетов расходов - нельзя менять только остатки счетов
    .expense: AccountPermissions(
        changeBudget: true,
        changeRemainder: false,
        linkToParentAccount: true
    )
]

private let isParentToPermissions: [Bool: AccountPermissions] = [
    // Разрешения для дочерних счетов - все разрешения
    false: AccountPermissions(
        changeBudget: true,
        changeRemainder: true,
        linkToParentAccount: true
    ),
    // Разрешения для родительских счетов - нельзя менять остатки счетов, создавать транзакции и привязывать к родительским счетам
    true: AccountPermissions(
        changeBudget: true,
        changeRemainder: true,
        linkToParentAccount: true
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
        joinedPermissions.linkToParentAccount = joinedPermissions.linkToParentAccount && permission.linkToParentAccount
    }
    return joinedPermissions
}
