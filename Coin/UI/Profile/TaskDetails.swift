//
//  TaskDetails.swift
//  Coin
//
//  Created by Илья on 29.04.2024.
//

import SwiftUI

struct TaskDetails: View {
    
    let task: SyncTask
    
    var body: some View {
        Form {
            HStack {
                Text("ID:")
                Spacer()
                Text("\(task.id)")
            }
            HStack {
                Text("Название действия:")
                Spacer()
                Text("\(task.actionName)")
            }
            HStack {
                Text("Количество попыток:")
                Spacer()
                Text("\(task.tryCount)")
            }
            HStack {
                Text("Локальный идентификатор объекта:")
                Spacer()
                Text("\(task.localID)")
            }
            Section(header: Text("Параметры")) {
                ForEach(task.fields) { field in
                    HStack {
                        Text(field.name)
                        Spacer()
                        Text(field.value ?? "NULL")
                    }
                }
            }
            Section(header: Text("Ошибка")) {
                HStack {
                    Text(task.error ?? "")
                }
            }
        }
    }
}

#Preview {
    TaskDetails(task: SyncTask())
}
