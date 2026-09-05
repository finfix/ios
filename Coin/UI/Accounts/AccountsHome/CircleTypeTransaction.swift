//
//  OrderView.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI

struct CircleTypeTransaction: View {
    
    var imageName: String
    
    var body: some View {
        Circle()
            .frame(width: 50, height: 50)
            .padding(20)
            .foregroundColor(.gray)
            .overlay {
                Image(systemName: imageName)
                    .foregroundColor(.black)
                    .font(.system(size: 20))
            }
    }
}
