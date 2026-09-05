//
//  TransactionFilterView.swift
//  Coin
//
//  Created by Илья on 03.11.2023.
//

import SwiftUI

struct TransactionFiltersRowItem: View {

    var text: String
    var color: Color
    var onRemove: () -> Void

    var body: some View {
        HStack {
            Text(text)
            Button(action: onRemove) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
        }
            .font(.callout)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                RoundedRectangle(cornerRadius: 100)
                    .foregroundStyle(color)
            }
    }
}
