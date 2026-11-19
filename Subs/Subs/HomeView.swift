//
//  HomeView.swift
//  Onglet « Abonnements » : total, essais qui se terminent, prochains prélèvements, liste.
//

import SwiftUI
import Combine
import UserNotifications
import UIKit

struct HomeView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.openURL) private var openURL
    @ObservedObject var store: SubscriptionStore
    @ObservedObject var purchases: PurchaseManager

    @AppStorage(SettingsKey.listSort) private var sortRaw = ListSort.nextPayment.rawValue
    @State private var showAdd = false
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var showFeedback = false
    @State private var showCancelled = false

    private var sort: ListSort { ListSort(rawValue: sortRaw) ?? .nextPayment }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    if store.subscriptions.isEmpty {
                        emptyState
                    } else {
                        SummaryCard(store: store)
                        if store.notificationStatus == .denied && store.hasReminders {
                            notificationsBanner
                        }
                        trialSection
                        upcomingSection
                        listSection
                        cancelledSection
                        if !purchases.isPro { freeCounter }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .background { AppBackground() }
            .overlay(alignment: .bottomTrailing) {
                if !store.subscriptions.isEmpty { addButton }
            }
            .navigationTitle(loc("home_title"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showFeedback = true } label: {
                        Image(systemName: "lightbulb")
                    }
                    .accessibilityLabel(loc("feedback_title"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(loc("settings_title"))
                }
            }
            .navigationDestination(for: UUID.self) { id in
                SubscriptionDetailView(store: store, subscriptionID: id)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddSubscriptionView(store: store)
                .appAppearance()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(purchases: purchases)
                .appAppearance()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(store: store, purchases: purchases)
                .appAppearance()
        }
        .sheet(isPresented: $showFeedback) {
            FeedbackView()
                .appAppearance()
        }
    }

    private func addTapped() {
        Haptics.tap()
        if store.canAdd(isPro: purchases.isPro) {
            showAdd = true
        } else {
            showPaywall = true
        }
    }

    // MARK: Bouton +

    private var addButton: some View {
        Button(action: addTapped) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(theme.diagonalGradient, in: Circle())
                .shadow(color: theme.primary.opacity(0.45), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 16)
        .accessibilityLabel(loc("add_title"))
    }

    // MARK: Vide

    private var emptyState: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 30)
            Image(systemName: "creditcard.and.123")
                .font(.system(size: 54))
                .foregroundStyle(theme.diagonalGradient)
                .frame(width: 140, height: 140)
                .glassBackground(in: Circle())
            VStack(spacing: 10) {
                Text(loc("empty_title"))
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(loc("empty_text"))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button(action: addTapped) {
                PrimaryButtonLabel(title: loc("empty_button"), icon: "plus")
            }
            .buttonStyle(.plain)
            Label(loc("empty_privacy"), systemImage: "lock.fill")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 12)
    }

    // MARK: Notifications désactivées

    private var notificationsBanner: some View {
        Button {
            if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bell.slash.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc("notif_off_title"))
                        .font(.subheadline.bold())
                    Text(loc("notif_off_text"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(loc("enable"))
                    .font(.subheadline.bold())
                    .foregroundStyle(theme.primary)
            }
            .foregroundStyle(.primary)
            .glassCard(cornerRadius: 22, padding: 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: Essais gratuits

    @ViewBuilder
    private var trialSection: some View {
        let trials = store.trialsEndingSoon()
        if !trials.isEmpty {
            VStack(spacing: 10) {
                ForEach(trials) { sub in
                    NavigationLink(value: sub.id) {
                        HStack(spacing: 14) {
                            Image(systemName: "hourglass")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.orange)
                                .frame(width: 46, height: 46)
                                .glassBackground(in: Circle(), tint: .orange.opacity(0.22))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(loc("trial_card_title", sub.name))
                                    .font(.headline)
                                    .lineLimit(1)
                                Text(loc("trial_card_text", L10n.relativeDay(sub.anchorDate), L10n.money(sub.share)))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                        .padding(14)
                        .glassBackground(in: RoundedRectangle(cornerRadius: 22, style: .continuous), tint: .orange.opacity(0.12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Prochains prélèvements

    @ViewBuilder
    private var upcomingSection: some View {
        let items = store.upcoming(withinDays: 30)
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(title: loc("upcoming_title"),
                             trailing: loc("upcoming_total", L10n.money(items.reduce(0) { $0 + $1.subscription.share })))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items.prefix(12)) { item in
                            NavigationLink(value: item.subscription.id) {
                                upcomingCard(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
                .scrollClipDisabled()
                .padding(.horizontal, -16)
            }
        }
    }

    private func upcomingCard(_ item: UpcomingPayment) -> some View {
        let days = L10n.daysUntil(item.date)
        return VStack(alignment: .leading, spacing: 10) {
            SubIcon(subscription: item.subscription, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.subscription.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(L10n.money(item.subscription.share))
                    .font(.headline)
                    .monospacedDigit()
            }
            Text(L10n.relativeDay(item.date))
                .font(.caption.weight(.bold))
                .foregroundStyle(days <= 2 ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
        }
        .foregroundStyle(.primary)
        .padding(14)
        .frame(width: 138, alignment: .leading)
        .glassBackground(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: Liste

    private var listSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(loc("list_title"))
                    .font(.title3.bold())
                Spacer()
                Menu {
                    Picker(loc("sort_title"), selection: $sortRaw) {
                        ForEach(ListSort.allCases) { option in
                            Text(option.title).tag(option.rawValue)
                        }
                    }
                } label: {
                    Label(sort.title, systemImage: "arrow.up.arrow.down")
                        .font(.subheadline.weight(.semibold))
                }
            }
            if store.active.isEmpty {
                Text(loc("list_none_active"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .glassCard(cornerRadius: 22, padding: 16)
            }
            ForEach(store.sorted(store.active, by: sort)) { sub in
                NavigationLink(value: sub.id) {
                    SubscriptionRow(subscription: sub)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Résiliés

    @ViewBuilder
    private var cancelledSection: some View {
        let cancelled = store.cancelled
        if !cancelled.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    withAnimation(.snappy) { showCancelled.toggle() }
                } label: {
                    HStack(alignment: .firstTextBaseline) {
                        Text(loc("cancelled_title", cancelled.count))
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                        Image(systemName: "chevron.down")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(showCancelled ? 0 : -90))
                        Spacer()
                        Text(loc("saved_total", L10n.money(store.totalSaved)))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }
                .buttonStyle(.plain)

                if showCancelled {
                    ForEach(cancelled) { sub in
                        NavigationLink(value: sub.id) {
                            SubscriptionRow(subscription: sub)
                                .opacity(0.75)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: Version gratuite

    private var freeCounter: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.yellow)
                Text(loc("free_counter", store.active.count, AppConfig.freeSubscriptionLimit))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(loc("unlock"))
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(theme.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassBackground(in: Capsule(), interactive: true)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Carte du total

struct SummaryCard: View {
    @Environment(\.appTheme) private var theme
    @ObservedObject var store: SubscriptionStore
    @AppStorage(SettingsKey.yearlyMode) private var yearly = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(yearly ? loc("summary_per_year") : loc("summary_per_month"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Picker(loc("summary_mode"), selection: $yearly) {
                    Text(loc("mode_month")).tag(false)
                    Text(loc("mode_year")).tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
                .labelsHidden()
            }

            Text(L10n.money(yearly ? store.yearlyTotal : store.monthlyTotal))
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.diagonalGradient)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            HStack(spacing: 8) {
                pill(icon: "sun.max.fill", text: loc("summary_per_day", L10n.money(store.dailyTotal)))
                pill(icon: "square.stack.fill", text: loc("summary_active", store.active.count))
            }

            if let next = store.upcoming(withinDays: 400).first {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(theme.primary)
                    Text(loc("summary_next", next.subscription.name, L10n.relativeDay(next.date), L10n.money(next.subscription.share)))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackground(in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .animation(.snappy, value: yearly)
    }

    private func pill(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassBackground(in: Capsule())
    }
}
