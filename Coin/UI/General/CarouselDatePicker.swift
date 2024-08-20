//
//  CarouselDatePicker.swift
//  Coin
//
//  Created by Илья on 17.08.2024.
//

import SwiftUI

struct CarouselDatePicker: View {
    
    @Binding var selectedDate: Date
    
    // Массив дат для отображения, начиная с сегодняшней даты и до 90 дней в прошлом
    var dates: [Date] {
        var datesArray: [Date] = []
        for i in 0...90 {
            if let date = Calendar.current.date(byAdding: .day, value: i-90, to: Date()) {
                datesArray.append(date)
            }
        }
        return datesArray
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(dates, id: \.self) { date in
                    Button {
                        selectedDate = date
                    } label: {
                        VStack {
                            Text(formatDate(date).uppercased())
                                .bold()
                            Text(formatDayOfWeek(date).uppercased())
                                .font(.caption)
                        }
                    }
                    .padding()
                    Divider()
                        .frame(height: 40)
                }
                
                // Календарная иконка
                Image(systemName: "calendar")
                    .font(.title)
                    .padding()
                    .overlay{
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .blendMode(.destinationOver)
                    }
            }
            .buttonStyle(.plain)
        }
        .defaultScrollAnchor(.trailing)
    }
    
    // Форматирование даты
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: date)
    }
    
    // Форматирование дня недели
    func formatDayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

#Preview {
    CarouselDatePicker(selectedDate: .constant(Date()))
}
