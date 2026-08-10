//
//  CopyableIDText.swift
//  Coin
//

import SwiftUI

/// Строка "ID: <значение>" — тап копирует id в буфер обмена и на секунду
/// показывает рядом плашку "Скопировано".
struct CopyableIDText: View {
    var id: String

    var body: some View {
        Text("ID: \(id)")
            .copyableOnTap(id)
    }
}
