//
//  TagsList.swift
//  Coin
//
//  Created by Илья on 21.04.2024.
//

import SwiftUI

enum TagsListRoute: Hashable {
    case editTag(Tag)
    case createTag
}

struct TagsList: View {
    
    @State private var vm: TagsListViewModel
    @Environment (AlertManager.self) private var alert
    @Environment(PathSharedState.self) var path
    
    init(
        accountGroup: AccountGroup
    ) {
        self.vm = TagsListViewModel(accountGroup: accountGroup)
    }
    
    var body: some View {
        List {
            ForEach(vm.tags) { tag in
                NavigationLink(value: TagsListRoute.editTag(tag)) {
                    Text(tag.name)
                }
                .buttonStyle(.plain)
            }
            .onDelete {
                for i in $0.makeIterator() {
                    Task {
                        do {
                            try await vm.deleteTag(vm.tags[i])
                        } catch {
                            alert(error)
                        }
                    }
                }
            }
        }
        .toolbar{
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: TagsListRoute.createTag) {
                    Image(systemName: "plus")
                }
            }
        }
        .task{
            do {
                try await vm.load()
            } catch {
                alert(error)
            }
        }
    }
}

#Preview {
    TagsList(accountGroup: AccountGroup())
}
