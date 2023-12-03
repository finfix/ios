//
//  TransactionFilterView.swift
//  Coin
//
//  Created by Илья on 03.11.2023.
//

import SwiftUI

struct TransactionFilterView: View {
    
    @Environment(\.dismiss) var dissmiss
    @Binding var dateFrom: Date?
    @Binding var dateTo: Date?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Дата", systemImage: "calendar")
                    Сalendar(buttonName: "C", date: $dateFrom)
                    Сalendar(buttonName: "По", date: $dateTo)
                }
            }
            .datePickerStyle(.graphical)
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Готово") { dissmiss() }
                }
            }
        }
    }
}

private struct Сalendar: View {
    
    var buttonName: String
    @State private var isCalendarShowing = false
    @Binding var date: Date?
    
    var body: some View {
        Group {
            Button {
                withAnimation {
                    isCalendarShowing.toggle()
                }
            } label: {
                Text(buttonName)
                Spacer()
                Group {
                    if let date {
                        Text(date, style: .date)
                    } else {
                        Text("Дата не выбрана")
                    }
                }
                .foregroundStyle(.secondary)
                if date != nil {
                    Button {
                        withAnimation {
                            date = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .buttonStyle(.plain)
            if isCalendarShowing {
                DatePicker(buttonName,
                           selection: Binding<Date>(get: {date ?? Date()}, set: {date = $0}),
                           displayedComponents: .date)
            }
        }
    }
}

#Preview {
    TransactionFilterView(dateFrom: .constant(Date()), dateTo: .constant(Date()))
}
