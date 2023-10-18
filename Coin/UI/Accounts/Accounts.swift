//
//  OrderView.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI

struct Accounts: View {
    
    @Environment(ModelData.self) var modelData
    
    // TODO: Сделать универсальными
    @State var showDebts = false
    @State var showInvestment = false
    @State var showCredit = false
    
    @State var showCreate = false
    @State var currentIndex = 0
    
    @State var chooseBlurIsOpened = false
    @State var transactionType: TransactionType = .consumption
        
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 30) {
                    // Быстрая статистика
                    Header()
                    ScrollView {
                        Text("Карты и счета")
                        SnapCarouselView(spacing: 30, index: $currentIndex, items: modelData.accounts.filter { $0.visible && ($0.type == .regular)}) { account in
                            GeometryReader { proxy in
                                AccountCard(size: proxy.size, account: account)
                            }
                        }
                        .frame(height: 150)
        
                        AccountTypeDetailsView(header: "Инвестиции", accounts: modelData.accounts.filter { ($0.type == .investments) && ($0.visible) } )
                        AccountTypeDetailsView(header: "Долги", accounts: modelData.accounts.filter { ($0.type == .debt) && ($0.visible) } )
                        AccountTypeDetailsView(header: "Кредиты", accounts: modelData.accounts.filter { ($0.type == .credit) && ($0.visible) } )
                    }
                }
                .blur(radius: chooseBlurIsOpened ? 5 : 0)
        
        
                Group {
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            chooseBlurIsOpened.toggle()
                        }
                    } label: {
                        CircleTypeTransaction(imageName: chooseBlurIsOpened ? "arrow.uturn.backward" : "plus")
                    }
                    
                    NavigationLink(isActive: $showCreate) {
                        CreateTransactionView(isOpeningFrame: $showCreate, transactionType: transactionType)
                    } label: {}

                    if chooseBlurIsOpened {
                        Button {
                            transactionType = .consumption
                            showCreate = true
                        } label: {
                            CircleTypeTransaction(imageName: "minus")
                        }
                        .padding(.bottom, 90)
                        
                        Button {
                            transactionType = .income
                            showCreate = true
                        } label: {
                            CircleTypeTransaction(imageName: "plus")
                        }
                        .padding(.trailing, 90)
                        
                        Button {
                            transactionType = .transfer
                            showCreate = true
                        } label: {
                            CircleTypeTransaction(imageName: "arrow.left.arrow.right")
                        }
                        .padding(.trailing, 75)
                        .padding(.bottom, 75)
                    }
                }
            }
            .onAppear(perform: modelData.getAccounts)
            .onDisappear { chooseBlurIsOpened = false }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
    }
}
    
struct CircleTypeTransaction: View {
    
    var imageName: String
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: 50, height: 50)
                .padding(20)
                .foregroundColor(.gray)
            Image(systemName: imageName)
                .foregroundColor(.black)
                .font(.system(size: 20))
        }
    }
}
    
#Preview {
    Accounts()
}
