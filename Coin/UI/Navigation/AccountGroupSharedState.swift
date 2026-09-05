//
//  AppTabView.swift
//  Coin
//
//  Created by Илья on 15.11.2023.
//

import SwiftUI

@Observable
final class AccountGroupSharedState {
    var selectedAccountGroup = AccountGroup()
    // false, пока selectedAccountGroup — заглушка AccountGroup() из инициализатора, а не реальная
    // группа из AccountGroupSelector.task. Экраны, зависящие от выбранной группы (см.
    // AccountCirclesView), не должны запускать свой пайплайн загрузки, пока это не true — иначе
    // они успевают смонтироваться на заглушке и тут же пересоздаться заново, когда прилетает
    // реальная группа (см. разбор бага с пропадающими static locations).
    var isLoaded = false
}
