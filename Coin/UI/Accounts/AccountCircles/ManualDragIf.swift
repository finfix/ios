//
//  DraggableAccountCircleItem.swift
//  Coin
//
//  Created by Илья on 28.05.2024.
//

import SwiftUI

/// Обычный DragGesture для создания транзакции (см. AccountCirclesViewModel MARK: Создание
/// транзакции) — начинается сразу по движению пальца, без задержки .draggable. Не участвует в
/// .dropDestination напрямую: попадание в цель определяется вручную (updateManualDrag), по
/// зарегистрированным позициям кружков.
struct ManualDragIf: ViewModifier {
    let isEnabled: Bool
    let account: Account
    @Binding var vm: AccountCirclesViewModel
    @Binding var path: NavigationPath

    func body(content: Content) -> some View {
        if isEnabled {
            content.gesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .global)
                    .onChanged { value in
                        vm.updateManualDrag(location: value.location, draggedAccount: account)
                    }
                    .onEnded { _ in
                        vm.confirmManualDrag(path: $path)
                    }
            )
        } else {
            content
        }
    }
}
