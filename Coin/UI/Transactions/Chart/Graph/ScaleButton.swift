//
//  ChartView.swift
//  Coin
//
//  Created by Илья on 17.04.2024.
//

import SwiftUI
import Charts

struct ScaleButton: View {
    
    let imageName: String
    
    var body: some View {
        Circle()
            .frame(width: 30, height: 30)
            .foregroundColor(.gray)
            .overlay {
                Image(systemName: imageName)
                    .foregroundColor(.black)
                    .font(.system(size: 15))
            }
    }
}
