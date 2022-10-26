//
//  SearchBar.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI

struct SearchBar: View {
    
    @Binding var searchText: String
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color("Gray"))
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Поиск", text: $searchText)
            }
            .foregroundColor(.gray)
            .padding(.leading, 13)
        }
        .frame(height: 40)
        .cornerRadius(13)
        .padding()
    }
}

struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(searchText: .constant(""))
    }
}
