//
//  CalendarScreen.swift
//  Onglet « Calendrier » : les jours de prélèvement du mois, et le total du mois.
//

import SwiftUI
import Combine

struct CalendarScreen: View {
    @Environment(\.appTheme) private var theme
    @ObservedObject var store: SubscriptionStore

    @State private var month: Date = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    @State private var selectedDay: Date? = Calendar.current.startOfDay(for: .now)

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        NavigationStack {
            content(payments: store.payments(inMonthOf: month))
                .background { AppBackground() }
                .navigationTitle(loc("tab_calendar"))
                .navigationDestination(for: UUID.self) { id in
                    SubscriptionDetailView(store: store, subscriptionID: id)
                }
        }
    }

    private func content(payments: [Date: [Subscription]]) -> some View {
        let monthTotal = payments.values.joined().reduce(0) { $0 + $1.share }
        return ScrollView {
            VStack(spacing: 16) {
                monthHeader(total: monthTotal)
                grid(payments: payments)
                dayList(payments: payments)
            }
            .padding(16)
            .padding(.bottom, 20)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: En-tête

    private func monthHeader(total: Double) -> some View {
        HStack {
            GlassIconButton(icon: "chevron.left", accessibility: loc("calendar_previous")) { changeMonth(-1) }
            Spacer()
            VStack(spacing: 2) {
                Text(L10n.monthTitle(month))
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text(loc("calendar_month_total", L10n.money(total)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            .onTapGesture { goToToday() }
            Spacer()
            GlassIconButton(icon: "chevron.right", accessibility: loc("calendar_next")) { changeMonth(1) }
        }
    }

    private func changeMonth(_ delta: Int) {
        Haptics.tap()
        guard let newMonth = calendar.date(byAdding: .month, value: delta, to: month) else { return }
        withAnimation(.snappy) {
            month = newMonth
            let today = calendar.startOfDay(for: .now)
            selectedDay = calendar.isDate(today, equalTo: newMonth, toGranularity: .month) ? today : nil
        }
    }

    private func goToToday() {
        withAnimation(.snappy) {
            month = calendar.dateInterval(of: .month, for: .now)?.start ?? .now
            selectedDay = calendar.startOfDay(for: .now)
        }
    }

    // MARK: Grille

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: L10n.language)
        let symbols = formatter.veryShortStandaloneWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let first = max(0, min(symbols.count - 1, calendar.firstWeekday - 1))
        return Array(symbols[first...] + symbols[..<first])
    }

    /// Jours du mois, précédés de cases vides pour aligner le 1er sur le bon jour de la semaine.
    private var monthDays: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let weekday = calendar.component(.weekday, from: month)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            days.append(calendar.date(byAdding: .day, value: day - 1, to: month))
        }
        return days
    }

    private func grid(payments: [Date: [Subscription]]) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            ForEach(Array(monthDays.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day, subs: payments[day] ?? [])
                } else {
                    Color.clear.frame(height: 50)
                }
            }
        }
        .padding(12)
        .glassBackground(in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func dayCell(_ day: Date, subs: [Subscription]) -> some View {
        let isToday = calendar.isDateInToday(day)
        let isSelected = selectedDay.map { calendar.isDate($0, inSameDayAs: day) } ?? false
        return Button {
            Haptics.tap()
            withAnimation(.snappy) { selectedDay = day }
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.subheadline.weight(isToday || !subs.isEmpty ? .bold : .regular))
                    .foregroundStyle(isSelected ? AnyShapeStyle(.white) : (isToday ? AnyShapeStyle(theme.primary) : AnyShapeStyle(.primary)))
                HStack(spacing: 2) {
                    ForEach(subs.prefix(3)) { sub in
                        Circle()
                            .fill(sub.color)
                            .frame(width: 6, height: 6)
                            .overlay(Circle().strokeBorder(.white.opacity(isSelected ? 0.9 : 0), lineWidth: 1))
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.diagonalGradient)
                } else if isToday {
                    RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(theme.primary, lineWidth: 1.5)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(L10n.longDate(day)), \(subs.count)")
    }

    // MARK: Liste du jour / du mois

    @ViewBuilder
    private func dayList(payments: [Date: [Subscription]]) -> some View {
        if let selectedDay, calendar.isDate(selectedDay, equalTo: month, toGranularity: .month) {
            let subs = payments[calendar.startOfDay(for: selectedDay)] ?? []
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(title: L10n.longDate(selectedDay),
                             trailing: subs.isEmpty ? nil : L10n.money(subs.reduce(0) { $0 + $1.share }))
                if subs.isEmpty {
                    Text(loc("calendar_no_payment"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .glassCard(cornerRadius: 22, padding: 16)
                } else {
                    ForEach(subs) { sub in
                        NavigationLink(value: sub.id) {
                            SubscriptionRow(subscription: sub)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } else {
            let days = payments.keys.sorted()
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(title: loc("calendar_this_month"))
                if days.isEmpty {
                    Text(loc("calendar_no_payment_month"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .glassCard(cornerRadius: 22, padding: 16)
                }
                ForEach(days, id: \.self) { day in
                    ForEach(payments[day] ?? []) { sub in
                        NavigationLink(value: sub.id) {
                            HStack(spacing: 12) {
                                Text(L10n.shortDate(day))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 52, alignment: .leading)
                                SubscriptionRow(subscription: sub)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
