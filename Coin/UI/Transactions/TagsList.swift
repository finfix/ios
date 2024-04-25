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
    @Binding var path: NavigationPath
    
    init(
        accountGroup: AccountGroup,
        path: Binding<NavigationPath>
    ) {
        self.vm = TagsListViewModel(accountGroup: accountGroup)
        self._path = path
    }
    
    var body: some View {
        List {
            ForEach(vm.tags) { tag in
                Button {
                    path.append(TagsListRoute.editTag(tag))
                } label: {
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
                Button {
                    path.append(TagsListRoute.createTag)
                } label: {
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
    TagsList(accountGroup: AccountGroup(), path: .constant(NavigationPath()))
}
