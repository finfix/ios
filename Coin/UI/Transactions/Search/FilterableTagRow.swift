//
//  SearchView.swift
//  Coin
//
//  Created by Илья on 08.01.2025.
//

import SwiftUI

/// Строка подкатегории в поиске фильтров — тот же принцип, что и FilterableAccountRow: зелёный
/// плюс включает (filters.tags), красный минус исключает (filters.excludedTags).
struct FilterableTagRow: View {
    let tag: Tag
    let showAccountGroup: Bool
    let onInclude: () -> Void
    let onExclude: () -> Void

    var body: some View {
        HStack {
            HStack {
                if showAccountGroup {
                    Text(tag.accountGroup.name)
                    Text("•")
                }
                Text(tag.name)
            }
            Spacer()
            Button(action: onInclude) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
            Button(action: onExclude) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
}
