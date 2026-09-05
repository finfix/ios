//
//  UpdateTransaction.swift
//  Coin
//
//  Created by Илья on 20.10.2023.
//

import SwiftUI
import OSLog

struct Tags: View {
    
    var vm: EditTransactionViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(AlertManager.self) private var alert
    @Environment(PathSharedState.self) var path
    
    var body: some View {
        HStack {
            ScrollView(.horizontal) {
                VStack(alignment: .leading) {
                    HStack {
                        ForEach(Array(vm.tags.enumerated()), id: \.offset) { (i, tag) in
                            if i % 2 == 0 {
                                Button {
                                    withAnimation {
                                        if vm.currentTransaction.tags.contains(tag) {
                                            vm.currentTransaction.tags.removeAll { $0.id == tag.id }
                                        } else {
                                            vm.currentTransaction.tags.append(tag)
                                        }
                                    }
                                } label: {
                                    Text("#\(tag.name)")
                                        .font(.callout)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background {
                                            RoundedRectangle(cornerRadius: 100)
                                                .foregroundStyle(vm.currentTransaction.tags.contains(tag) ? Color.blue : Color.clear)
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 100)
                                                        .stroke(.secondary, lineWidth: 1)
                                                }
                                        }
                                }
                            }
                        }
                    }
                    HStack {
                        ForEach(Array(vm.tags.enumerated()), id: \.offset) { (i, tag) in
                            if i % 2 != 0 {
                                Button {
                                    withAnimation {
                                        if vm.currentTransaction.tags.contains(tag) {
                                            vm.currentTransaction.tags.removeAll { $0.id == tag.id }
                                        } else {
                                            vm.currentTransaction.tags.append(tag)
                                        }
                                    }
                                } label: {
                                    Text("#\(tag.name)")
                                        .font(.callout)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background {
                                            RoundedRectangle(cornerRadius: 100)
                                                .foregroundStyle(vm.currentTransaction.tags.contains(tag) ? Color.blue : Color.clear)
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 100)
                                                        .stroke(.secondary, lineWidth: 1)
                                                }
                                        }
                                }
                            }
                        }
                    }
                }
                .padding(1)
            }
            Button {
                path.path.append(EditTransactionRoute.tagsList)
            } label: {
                Image(systemName: "ellipsis")
            }
        }
        .buttonStyle(.plain)
    }
}
