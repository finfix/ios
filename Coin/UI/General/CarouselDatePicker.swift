//
//  CarouselDatePicker.swift
//  Coin
//
//  Created by Илья on 17.08.2024.
//

import SwiftUI

struct CarouselDatePicker: View {

    @Binding var selectedDate: Date

    // true — ничего не подсвечено и не проскроллено к какой-то конкретной дате, пока пользователь
    // явно не коснётся одной из них (см. EditTransaction: довнесение переноса — дата исходной
    // транзакции ДРУГОЙ группы не должна восприниматься как уже выбранная дата ЭТОЙ транзакции,
    // хотя технически currentTransaction.dateTransaction всё равно хранит какое-то стартовое
    // значение — Transaction того требует). По умолчанию false — везде остальное ведёт себя как раньше.
    var requiresExplicitSelection: Bool = false
    @State private var hasUserSelected = false

    // Массив дат для отображения, начиная с сегодняшней даты и до 90 дней в прошлом — плюс сама
    // выбранная дата, даже если она вне этого окна (например, редактируем старую транзакцию, или
    // дата в будущем): без этого она была бы не видна в карусели вовсе, хотя реально выбрана.
    var dates: [Date] {
        var datesArray: [Date] = []
        for i in 0...90 {
            if let date = Calendar.current.date(byAdding: .day, value: i-90, to: Date()) {
                datesArray.append(date)
            }
        }
        if !requiresExplicitSelection, !datesArray.contains(where: { Calendar.current.isDate($0, inSameDayAs: selectedDate) }) {
            datesArray.append(selectedDate)
            datesArray.sort()
        }
        return datesArray
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(dates, id: \.self) { date in
                        let isSelected = (!requiresExplicitSelection || hasUserSelected)
                            && Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        Button {
                            selectedDate = date
                            hasUserSelected = true
                        } label: {
                            VStack(spacing: 2) {
                                Text(formatDate(date).uppercased())
                                    .font(.callout.bold())
                                Text(formatDayOfWeek(date).uppercased())
                                    .font(.caption2)
                            }
                            .foregroundStyle(isSelected ? Color.accentColor : .primary)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.accentColor.opacity(0.15))
                            }
                        }
                        .id(date)
                        Divider()
                            .frame(height: 28)
                    }

                    // Календарная иконка
                    Image(systemName: "calendar")
                        .font(.title3)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
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
            // Якорь по умолчанию — правый край (совпадает с "сегодня", когда явно ничего не
            // выбирали особо). Если реально выбранная дата не "сегодня" (например, входим в
            // редактирование старой транзакции), доскролливаем к ней явно — но ТОЛЬКО следующим
            // тиком через DispatchQueue.main.async, иначе scrollTo срабатывает до того, как
            // ScrollView успевает разложить контент, и молча ничего не делает (в итоге видно
            // дефолтное левое положение, будто anchor вообще не применился).
            .defaultScrollAnchor(.trailing)
            .onAppear {
                guard !requiresExplicitSelection, !Calendar.current.isDateInToday(selectedDate) else { return }
                DispatchQueue.main.async {
                    proxy.scrollTo(dates.first { Calendar.current.isDate($0, inSameDayAs: selectedDate) }, anchor: .center)
                }
            }
        }
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
