//
//  SearchView.swift
//  Coin
//
//  Created by Илья on 08.01.2025.
//

import SwiftUI

/// Сворачиваемая секция фильтра — по умолчанию свёрнута (весь экран фильтров иначе стена
/// текста), заголовок раскрывает/прячет содержимое. Справа от заголовка, если передан count —
/// число доступных вариантов (например, сколько счетов подходит под уже введённую строку
/// поиска), чтобы было видно, есть ли смысл разворачивать, не разворачивая.
struct CollapsibleFilterSection<Content: View>: View {
    let title: String
    var count: Int? = nil
    @State private var isExpanded = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        Section {
            DisclosureGroup(isExpanded: $isExpanded) {
                content()
            } label: {
                HStack {
                    Text(title)
                    Spacer()
                    if let count {
                        Text("\(count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
