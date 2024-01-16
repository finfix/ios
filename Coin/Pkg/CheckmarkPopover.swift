//
//  CheckmarkPopover.swift
//  Coin
//
//  Created by Илья on 16.01.2024.
//

import SwiftUI

struct CheckmarkPopover: View {
    var body: some View {
        Image(systemName: "checkmark")
            .font(.system(.largeTitle,
                          design: .rounded)).bold()
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10,
                                                            style: .continuous))
    }
}

#Preview {
    CheckmarkPopover()
        .padding()
        .background(.blue)
}
