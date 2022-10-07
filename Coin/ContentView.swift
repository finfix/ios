//
//  ContentView.swift
//  Coin
//
//  Created by Илья on 07.10.2022.
//

import SwiftUI

struct ContentView: View {
    
    /// Добавляем Network в качестве EnvironmentObject
    @EnvironmentObject var network: Network
    
    var body: some View {
        /// В Body создаем ScrollView, и onAppear мы назовем нашу функцию getUsers:
        Text("All transactions")
            .font(.title).bold()
        ScrollView {
            /// Выполняем итерацию по network.users. Мы отобразим идентификатор каждого пользователя, имя, адрес электронной почты и телефон.
            VStack(alignment: .leading) {
                ForEach(network.transactions) { transaction in
                    HStack {
                        VStack(alignment: .leading) {
                            // Text("\(transaction.dateTransaction)")
                            Text("\(transaction.accountFromID) -> \(transaction.accountToID)")
                                .font(.footnote)
                            
                            if transaction.amountTo == transaction.amountFrom {
                                Text(String(format: "%.2f", transaction.amountTo))
                                    .font(.footnote)
                            } else {
                                Text(String(format: "%.2f", transaction.amountFrom) + " -> " + String(format: "%.2f", transaction.amountTo))
                                    .font(.footnote)
                            }
                        }
                        Spacer()
                        if let note = transaction.note {
                            Text(note)
                                .font(.footnote)
                        }
                    }
                    .frame(width: 300, alignment: .leading)
                    .padding()
                    .background(Color(#colorLiteral(red: 0.6667672396, green: 0.7527905703, blue: 1, alpha: 0.2662717301)))
                    .cornerRadius(20)
                }
            }
        }
        .onAppear {
            network.getTransaction()
        }
    }
}

/// Чтобы предварительный просмотр работал, не забудьте добавить environmentObject в предварительный просмотр ContentView, так как предварительный просмотр отличается от приложения:
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Network())
    }
}
