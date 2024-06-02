//
//  DeveloperToolsTab.swift
//  Coin
//
//  Created by Илья on 02.06.2024.
//

import SwiftUI

struct DeveloperToolsTab: View {
    
    @State var path = PathSharedState()
    
    var body: some View {
        NavigationStack(path: $path.path) {
            DeveloperTools()
                .navigationDestination(for: DeveloperToolsRoute.self) { screen in
                    switch screen {
                    case .tasksList: TasksList()
                    }
                }
                .navigationDestination(for: TasksListRoute.self) { screen in
                    switch screen {
                    case .taskDetails(let task): TaskDetails(task: task)
                    }
                }

        }
        .environment(path)
    }
}

#Preview {
    DeveloperToolsTab()
}
