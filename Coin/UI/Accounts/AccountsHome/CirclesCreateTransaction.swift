//
//  OrderView.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI

struct CirclesCreateTransaction: View {
    
    @Environment(PathSharedState.self) var path
    @Binding var chooseBlurIsOpened: Bool
    
    var body: some View {
        Group {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    chooseBlurIsOpened.toggle()
                }
            } label: {
                CircleTypeTransaction(imageName: chooseBlurIsOpened ? "arrow.uturn.backward" : "plus")
            }
            if chooseBlurIsOpened {
                NavigationLink(value: CirclesCreateTransactionRoute.createTrasnaction(.consumption)) {
                    CircleTypeTransaction(imageName: "minus")
                }
                .padding(.bottom, 90)
                
                NavigationLink(value: CirclesCreateTransactionRoute.createTrasnaction(.income)) {
                    CircleTypeTransaction(imageName: "plus")
                }
                .padding(.trailing, 90)
                
                NavigationLink(value: CirclesCreateTransactionRoute.createTrasnaction(.transfer)) {
                    CircleTypeTransaction(imageName: "arrow.left.arrow.right")
                }
                .padding(.trailing, 75)
                .padding(.bottom, 75)
            }
        }
        .onDisappear { chooseBlurIsOpened = false }
    }
}
