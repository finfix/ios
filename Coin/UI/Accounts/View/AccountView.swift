//
//  OrderView.swift
//  Coin
//
//  Created by Илья on 10.10.2022.
//

import SwiftUI
import RealmSwift

struct AccountView: View {
    
    @ObservedObject var vm = AccountViewModel()
    @EnvironmentObject var appSettings: AppSettings
    
    @ObservedResults (
            Account.self
        ) var accounts
    
    @State var showFilters = false
    @State var showDebts = false
    @State var showInvestment = false
    @State var showCredit = false
    @State var showCreate = false
    @State var currentIndex = 0
    
    @State var chooseBlurIsOpened = false
    @State var transactionType: TransactionTypes = .consumption
        
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 30) {
        
                    // Шапка
                    Header()
        
                    // Выбор группы счетов
                    SelectAccountGroup(name: $vm.selectedAccountGroupID)
        
                    ScrollView {
        
                        Text("Карты и счета")
                        SnapCarouselView(spacing: 30, index: $currentIndex, items: vm.accounts.filter { $0.visible && ($0.typeSignatura == "regular")}) { account in
                            GeometryReader { proxy in
        
                                let size = proxy.size
        
        
                                VStack(alignment: .leading) {
                                    HStack {
                                        Circle()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(.gray)
                                        Text(account.name)
                                    }
                                    
                                    Text("\(account.remainder)")
                                }
                                .frame(width: size.width, height: 150)
                                .background(Color("Gray"))
                                .cornerRadius(17)
        
                            }
                        }
                        .frame(height: 150)
        
                        HStack(spacing: 10) {
                            ForEach(accounts.indices, id: \.self) { index in
                                Circle()
                                    .fill(Color.black.opacity(currentIndex == index ? 0.5 : 0.1))
                                    .frame(width: 5)
                                    .scaleEffect(currentIndex == index ? 1.4 : 1)
                                    .animation(.spring(), value: currentIndex == index )
                            }
                        }
        
        
                        AccountTypeDetailsView(header: "Инвестиции", accounts: $accounts.filterB { ($0.typeSignatura == "investment") && ($0.visible) } )
        
                        AccountTypeDetailsView(header: "Долги", accounts: $accounts.filterB { ($0.typeSignatura == "debt") && ($0.visible) } )
        
                        AccountTypeDetailsView(header: "Кредиты", accounts: $accounts.filterB { ($0.typeSignatura == "credit") && ($0.visible) } )
        
                    }
                }
                .blur(radius: chooseBlurIsOpened ? 5 : 0)
        
        
                Group {
                    
                    Button {
                        chooseBlurIsOpened.toggle()
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
            .onAppear { vm.getAccount(appSettings) }
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
    
    struct AccountView_Previews: PreviewProvider {
        static var previews: some View {
            AccountView()
                .environmentObject(AppSettings())
        }
    }
