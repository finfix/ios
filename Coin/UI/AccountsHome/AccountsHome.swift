//
//  OrderView.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI
import SwiftData

struct AccountsHome: View {
    
    @AppStorage("accountGroupID") var selectedAccountsGroupID: Int = 0
    @Query var accounts: [Account]
    
    var filteredAccounts: [Account] {
        accounts.filter { $0.accountGroupID == selectedAccountsGroupID }
    }
    
    // TODO: Сделать универсальными
    @State var showDebts = false
    
    @State var showCreate = false
    @State var currentIndex = 0
    
    @State var chooseBlurIsOpened = false
    @State var transactionType: TransactionType = .consumption
        
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 30) {
                    VStack(spacing: 0) {
                        Header()
                        AccountsGroupSelector()
                    }
                    ScrollView {
                        Text("Карты и счета")
                        SnapCarouselView(spacing: 30, index: $currentIndex, items: filteredAccounts.filter { $0.visible && ($0.type == .regular)}) { account in
                            GeometryReader { proxy in
                                AccountCard(size: proxy.size, account: account)
                            }
                        }
                        .frame(height: 150)
        
                        AccountTypeDetailsView(header: "Долги", accounts: filteredAccounts.filter { ($0.type == .debt) && ($0.visible) } )
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
                .onDisappear { chooseBlurIsOpened = false }
            }
            .navigationDestination(isPresented: $showCreate) {
                CreateTransactionView(isOpeningFrame: $showCreate, transactionType: transactionType)
            }
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
    AccountsHome()
}
