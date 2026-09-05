//
//  DraggableAccountCircleItem.swift
//  Coin
//
//  Created by Илья on 28.05.2024.
//

import SwiftUI

/// `.draggable(_:)` не умеет условно отключаться параметром (в отличие от .disabled) — счёт
/// либо перетаскиваемый, либо нет, поэтому ветвим сборку view целиком.
struct DraggableIf: ViewModifier {
    let isEnabled: Bool
    let account: Account

    func body(content: Content) -> some View {
        if isEnabled {
            content.draggable(DraggedAccount(accountID: account.id)) {
                AccountCircleItemCircle(account: account)
                    .frame(width: 60, height: 60)
            }
        } else {
            content
        }
    }
}
