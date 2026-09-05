//
//  AccountSelectorField.swift
//  Coin
//

import SwiftUI

/// Маленький круглый значок счёта: цвет по типу + иконка счёта.
/// Родительские счета — с двойным кольцом, как на главном экране (AccountCircleItemCircle).
struct AccountIconCircle: View {
    var account: Account
    var diameter: CGFloat = 36

    var body: some View {
        Rectangle()
            .fill(accountTypeColor(account.type))
            .mask {
                ZStack {
                    if account.isParent && account.type != .balancing {
                        Circle()
                            .fill(.clear)
                            .strokeBorder(.black, lineWidth: 2)
                            .frame(width: diameter, height: diameter)
                        Circle()
                            .frame(width: diameter * 0.9, height: diameter * 0.9)
                    } else {
                        Circle()
                            .frame(width: diameter, height: diameter)
                    }
                }
            }
            .overlay {
                AsyncImage(url: URL.documentsDirectory.appending(path: account.icon.url)) { image in
                    image.image?
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: diameter * 0.5)
                }
            }
            .frame(width: diameter, height: diameter)
    }
}
