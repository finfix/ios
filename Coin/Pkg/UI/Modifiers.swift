//
//  TextField.swift
//  Coin
//
//  Created by Илья on 20.10.2022.
//

import SwiftUI

struct CustomTextField: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(.secondary)
            .padding()
            .frame(height: 40)
            .background(Color("Gray"))
            .cornerRadius(13)
            .padding()
    }
}

struct CustomButton: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(.black)
            .padding(13)
            .frame(height: 40)
            .background(.gray)
            .cornerRadius(13)
            .padding()
    }
}
struct TextField_Previews: PreviewProvider {
    static var previews: some View {
        
        Text("Hello, my friend")
            .modifier(CustomTextField())
    }
}
