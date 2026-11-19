//
//  StatsScreen.swift
//  Onglet « Stats » : où part l'argent, les 12 prochains mois, les plus chers, les économies.
//

import SwiftUI
import Combine
import Charts

struct StatsScreen: View {
    @Environment(\.appTheme) private var theme
    @ObservedObject var store: SubscriptionStore

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if store.subscriptions.isEmpty {
                        ContentUnavailableView(loc("stats_empty_title"), systemImage: "chart.pie",
                                               description: Text(loc("stats_empty_text")))
                            .padding(.top, 60)
                    } else {
                        totalsGrid
                        if !store.active.isEmpty {
                            categoryCard
                            monthsCard
                            topCard
                        }
                        if !store.cancelled.isEmpty { savingsCard }
                    }
                }
                .padding(16)
                .padding(.bottom, 20)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .background { AppBackground() }
            .navigationTitle(loc("tab_stats"))
            .navigationDestination(for: UUID.self) { id in
                SubscriptionDetailView(store: store, subscriptionID: id)
            }
        }
    }

    // MARK: Totaux

    private var totalsGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            tile(icon: "calendar", color: theme.primary, value: L10n.money(store.monthlyTotal), label: loc("stats_per_month"))
            tile(icon: "sum", color: theme.secondary, value: L10n.money(store.yearlyTotal), label: loc("stats_per_year"))
            tile(icon: "hourglass.bottomhalf.filled", color: .orange, value: L10n.money(store.yearlyTotal * 5), label: loc("stats_five_years"))
            tile(icon: "square.stack.fill", color: .blue, value: "\(store.active.count)", label: loc("stats_active"))
        }
    }

    private func tile(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassBackground(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: Catégories

    private var categoryCard: some View {
        let data = store.monthlyByCategory()
        let total = max(0.01, data.reduce(0) { $0 + $1.amount })
        return VStack(alignment: .leading, spacing: 16) {
            Text(loc("stats_by_category"))
                .font(.headline)
            ZStack {
                Chart(data) { item in
                    SectorMark(angle: .value("amount", item.amount), innerRadius: .ratio(0.64), angularInset: 2)
                        .cornerRadius(5)
                        .foregroundStyle(item.category.color)
                }
                .chartLegend(.hidden)
                VStack(spacing: 2) {
                    Text(L10n.money(store.monthlyTotal))
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(loc("per_monthly"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 110)
            }
            .frame(height: 220)

            VStack(spacing: 10) {
                ForEach(data) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.category.icon)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(item.category.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Text(item.category.title)
                            .font(.subheadline)
                        Spacer()
                        Text(L10n.money(item.amount))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                        Text("\(Int((item.amount / total * 100).rounded())) %")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: 12 prochains mois

    private var monthsCard: some View {
        let months = store.nextMonthsTotals(12)
        let peak = months.max { $0.amount < $1.amount }
        return VStack(alignment: .leading, spacing: 14) {
            Text(loc("stats_next_months"))
                .font(.headline)
            Chart(months) { item in
                BarMark(x: .value("month", item.label), y: .value("amount", item.amount))
                    .foregroundStyle(theme.diagonalGradient)
                    .cornerRadius(5)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(L10n.compactMoney(amount))
                        }
                    }
                }
            }
            .frame(height: 200)
            if let peak, peak.amount > 0 {
                Label(loc("stats_peak", L10n.monthTitle(peak.month), L10n.money(peak.amount)), systemImage: "arrow.up.right")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .glassCard()
    }

    // MARK: Les plus chers

    private var topCard: some View {
        let top = Array(store.active.sorted { $0.yearlyCost > $1.yearlyCost }.prefix(5))
        return VStack(alignment: .leading, spacing: 12) {
            Text(loc("stats_top"))
                .font(.headline)
            ForEach(Array(top.enumerated()), id: \.element.id) { index, sub in
                NavigationLink(value: sub.id) {
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .foregroundStyle(.secondary)
                            .frame(width: 18)
                        SubIcon(subscription: sub, size: 34)
                        Text(sub.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Spacer()
                        Text(loc("stats_per_year_value", L10n.money(sub.yearlyCost)))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                    .foregroundStyle(.primary)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .glassCard()
    }

    // MARK: Économies

    private var savingsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(loc("stats_saved_title"), systemImage: "leaf.fill")
                .font(.headline)
                .foregroundStyle(.green)
            Text(L10n.money(store.totalSaved))
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(.green)
                .contentTransition(.numericText())
            Text(loc("stats_saved_text", store.cancelled.count, L10n.money(store.yearlySavedProjection)))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackground(in: RoundedRectangle(cornerRadius: 26, style: .continuous), tint: .green.opacity(0.08))
    }
}
