//
//  SearchView.swift
//  Coin
//
//  Created by Илья on 08.01.2025.
//

import SwiftUI

struct ExpandableDatePicker: View {
    
    var buttonName: String
    @Binding var isCalendarShowing: Bool
    @Binding var date: Date?
    var showClearButton: Bool = true
    var normalizeToEndOfDay: Bool = false

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
                if date != nil && showClearButton {
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
                           selection: Binding<Date>(get: {date ?? Date()}, set: { newValue in
                               if normalizeToEndOfDay {
                                   date = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: newValue)
                               } else {
                                   date = newValue
                               }
                           }),
                           displayedComponents: .date)
                .datePickerStyle(.graphical)
            }
        }
    }
}
