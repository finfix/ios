//
//  SelectAccountGroup.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI

struct SelectAccountGroup: View {
    
    @Binding var name: Int
    
    var body: some View {
        HStack(spacing: 80) {
            Image(systemName: "chevron.left")
            Text("\(name)")
            Image(systemName: "chevron.right")
        }
    }
}

struct SelectAccountGroup_Previews: PreviewProvider {
    static var previews: some View {
        SelectAccountGroup(name: .constant(1))
    }
}
