//
//  CreateAccount.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI
import Factory

struct IconPicker: View {
    
    @Injected(\.service) private var service
    
    @State var icons: [Icon] = []
    @Environment(\.dismiss) var dismiss

    @Binding var selectedIcon: Icon
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
                ForEach(icons) { icon in
                    Button {
                        selectedIcon = icon
                        dismiss()
                    } label: {
                        Circle()
                            .fill(.orange)
                            .frame(height: 60)
                            .overlay{
                                AsyncImage(url: URL.documentsDirectory.appending(path: icon.url)) { image in
                                    image.image?
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 30)
                                }
                            }
                    }
                }
            }
        }
        .task {
            do {
                self.icons = try await service.getIcons()
            } catch {
                
            }
        }
    }
}
