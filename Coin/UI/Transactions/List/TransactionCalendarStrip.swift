//
//  TransactionCalendarStrip.swift
//  Coin
//

import SwiftUI

/// Горизонтальный календарь дней, у которых есть транзакции — тап по дню прокручивает
/// список транзакций до этого дня, чтобы можно было быстро сориентироваться в списке.
struct TransactionCalendarStrip: View {
    let days: [Date]
    var isLoading: Bool = false
    let onSelect: (Date) -> Void

    // Самый правый видимый день ленты — если он не совпадает с последним (самым свежим) днём,
    // значит пользователь проскроллил календарь в прошлое, и стоит показать кнопку "Сегодня".
    @State private var trailingVisibleDay: Date?

    /// Дни, сгруппированные по месяцам (в исходном хронологическом порядке) — перед каждой
    /// новой группой в ленту вставляется подпись месяца, чтобы при горизонтальном скролле
    /// всегда было понятно, в каком месяце сейчас находишься.
    private var monthGroups: [(month: Date, days: [Date])] {
        let calendar = Calendar.current
        var groups: [(month: Date, days: [Date])] = []
        for day in days {
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: day))!
            if groups.last?.month == monthStart {
                groups[groups.count - 1].days.append(day)
            } else {
                groups.append((month: monthStart, days: [day]))
            }
        }
        return groups
    }

    var body: some View {
        if !days.isEmpty {
            ScrollViewReader { proxy in
                HStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(monthGroups, id: \.month) { group in
                                Text(group.month.formatted(.dateTime.month(.abbreviated).year(.twoDigits)).uppercased())
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                    .fixedSize()
                                    .frame(height: 44)
                                    .padding(.horizontal, 4)
                                    .overlay(alignment: .trailing) {
                                        Divider().padding(.vertical, 8)
                                    }

                                ForEach(group.days, id: \.self) { day in
                                    Button {
                                        onSelect(day)
                                    } label: {
                                        VStack(spacing: 2) {
                                            Text(day.formatted(.dateTime.weekday(.abbreviated)))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            Text(day.formatted(.dateTime.day()))
                                                .font(.subheadline)
                                                .fontWeight(Calendar.current.isDateInToday(day) ? .bold : .regular)
                                        }
                                        .frame(width: 40, height: 44)
                                        .background {
                                            if Calendar.current.isDateInToday(day) {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color.accentColor.opacity(0.15))
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .id(day)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                    }
                    .disabled(isLoading)
                    .scrollPosition(id: $trailingVisibleDay, anchor: .trailing)
                    .overlay {
                        // Если выбрали дату, которой ещё нет среди загруженных строк, идёт
                        // точечный запрос окна транзакций вокруг неё — показываем прогресс
                        // поверх календаря.
                        if isLoading {
                            ZStack {
                                Color(.systemBackground).opacity(0.6)
                                ProgressView()
                            }
                        }
                    }

                    // Занимает своё место в HStack (а не плавает поверх ленты) и появляется,
                    // только когда лента прокручена в прошлое — справа виден не самый свежий
                    // день.
                    if let lastDay = days.last, trailingVisibleDay != lastDay {
                        Button {
                            // Тот же путь, что и обычный тап по дню — jumpTo полностью
                            // сбрасывает список и грузит заново от сегодня, так что никакие
                            // ограничения от предыдущего прыжка в прошлое не остаются.
                            onSelect(lastDay)
                            withAnimation {
                                proxy.scrollTo(lastDay, anchor: .trailing)
                            }
                        } label: {
                            Image(systemName: "arrow.uturn.forward.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Color.accentColor)
                        }
                        .padding(.horizontal, 8)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .background(.bar)
                .animation(.default, value: trailingVisibleDay == days.last)
                .onAppear {
                    // Показываем сразу самые свежие дни (список транзакций упорядочен по
                    // убыванию даты, самое актуальное — вверху).
                    if let lastDay = days.last {
                        proxy.scrollTo(lastDay, anchor: .trailing)
                    }
                }
            }
        }
    }
}

#Preview {
    TransactionCalendarStrip(
        days: (0..<15).map { Calendar.current.date(byAdding: .day, value: -$0, to: Date())! }.reversed().map { $0 },
        onSelect: { _ in }
    )
}
