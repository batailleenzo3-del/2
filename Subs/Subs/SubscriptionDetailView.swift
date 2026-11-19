//
//  SubscriptionDetailView.swift
//  Fiche d'un abonnement : coût réel, prochains prélèvements, résiliation.
//

import SwiftUI
import Combine
import StoreKit

struct SubscriptionDetailView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @ObservedObject var store: SubscriptionStore
    let subscriptionID: UUID

    @AppStorage(SettingsKey.reviewRequested) private var reviewRequested = false
    @State private var showEditor = false
    @State private var confirmCancel = false
    @State private var confirmDelete = false
    @State private var confetti = 0
    @State private var celebration: String?

    var body: some View {
        Group {
            if let sub = store.subscription(subscriptionID) {
                content(sub)
            } else {
                ContentUnavailableView(loc("detail_missing"), systemImage: "questionmark.circle")
            }
        }
        .background { AppBackground() }
        .overlay { ConfettiView(trigger: confetti) }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ sub: Subscription) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                header(sub)
                if let celebration {
                    celebrationCard(celebration)
                }
                if sub.isActive {
                    infoGrid(sub)
                    paymentsCard(sub)
                } else {
                    cancelledCard(sub)
                }
                if !sub.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(loc("editor_notes"), systemImage: "note.text")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(sub.notes)
                    }
                    .glassCard()
                }
                actions(sub)
            }
            .padding(16)
            .padding(.bottom, 20)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(loc("edit")) { showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                SubscriptionEditor(store: store, original: sub, isNew: false) { result in
                    showEditor = false
                    if result == .deleted { dismiss() }
                }
            }
            .appAppearance()
        }
        .confirmationDialog(loc("cancel_confirm_title", sub.name), isPresented: $confirmCancel, titleVisibility: .visible) {
            Button(loc("cancel_confirm_button")) { markCancelled(sub) }
            Button(loc("cancel"), role: .cancel) {}
        } message: {
            Text(loc("cancel_confirm_text"))
        }
        .confirmationDialog(loc("delete_confirm", sub.name), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(loc("delete"), role: .destructive) {
                store.delete(sub.id)
                dismiss()
            }
            Button(loc("cancel"), role: .cancel) {}
        }
    }

    // MARK: En-tête

    private func header(_ sub: Subscription) -> some View {
        VStack(spacing: 12) {
            SubIcon(subscription: sub, size: 84)
            Text(sub.name)
                .font(.system(.title, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
            Label(sub.category.title, systemImage: sub.category.icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(L10n.money(sub.share))
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                Text(sub.cycle.perTitle)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            if sub.sharedWith > 1 {
                Text(loc("detail_shared", L10n.money(sub.price), sub.sharedWith))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if sub.isInTrial() {
                Label(loc("detail_trial", L10n.longDate(sub.anchorDate)), systemImage: "hourglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glassBackground(in: Capsule(), tint: .orange.opacity(0.18))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .glassBackground(in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private func celebrationCard(_ text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "party.popper.fill")
                .font(.title)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 3) {
                Text(loc("celebrate_title"))
                    .font(.headline)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .glassCard()
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: Infos

    private func infoGrid(_ sub: Subscription) -> some View {
        let next = sub.nextPayment()
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            infoTile(icon: "calendar", color: theme.primary, title: loc("detail_next"),
                     value: next.map { L10n.shortDate($0) } ?? "—",
                     caption: next.map { L10n.relativeDay($0) })
            infoTile(icon: "bell.fill", color: .orange, title: loc("detail_reminder"),
                     value: ReminderOption.title(for: sub.reminderDays), caption: nil)
            infoTile(icon: "calendar.badge.clock", color: .blue, title: loc("detail_per_month"),
                     value: L10n.money(sub.monthlyCost), caption: nil)
            infoTile(icon: "sum", color: .purple, title: loc("detail_per_year"),
                     value: L10n.money(sub.yearlyCost), caption: loc("detail_five_years", L10n.money(sub.yearlyCost * 5)))
        }
    }

    private func infoTile(icon: String, color: Color, title: String, value: String, caption: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .padding(16)
        .glassBackground(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func paymentsCard(_ sub: Subscription) -> some View {
        let dates = sub.upcomingPayments(6)
        return VStack(alignment: .leading, spacing: 12) {
            Text(loc("detail_upcoming"))
                .font(.headline)
            ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                HStack {
                    Circle()
                        .fill(index == 0 ? AnyShapeStyle(theme.gradient) : AnyShapeStyle(Color.secondary.opacity(0.35)))
                        .frame(width: 8, height: 8)
                    Text(L10n.longDate(date))
                        .font(.subheadline)
                    Spacer()
                    Text(L10n.money(sub.share))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
                if index < dates.count - 1 { Divider() }
            }
        }
        .glassCard()
    }

    private func cancelledCard(_ sub: Subscription) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 38))
                .foregroundStyle(.green)
            Text(loc("detail_cancelled_on", L10n.longDate(sub.cancelledDate ?? .now)))
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(L10n.money(sub.savedSinceCancellation()))
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(.green)
                .contentTransition(.numericText())
            Text(loc("detail_saved_label", L10n.money(sub.yearlyCost)))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .glassBackground(in: RoundedRectangle(cornerRadius: 26, style: .continuous), tint: .green.opacity(0.1))
    }

    // MARK: Actions

    private func actions(_ sub: Subscription) -> some View {
        VStack(spacing: 12) {
            if sub.isActive {
                if let link = sub.manageLink {
                    Button {
                        openURL(link)
                    } label: {
                        PrimaryButtonLabel(title: sub.billedByApple ? loc("manage_apple") : loc("manage_site"),
                                           icon: "arrow.up.forward.app")
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    confirmCancel = true
                } label: {
                    Label(loc("mark_cancelled"), systemImage: "scissors")
                        .font(.headline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .glassBackground(in: Capsule(), interactive: true)
                }
                .buttonStyle(.plain)
                Text(loc("mark_cancelled_hint"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            } else {
                Button {
                    store.reactivate(sub.id)
                    celebration = nil
                    Haptics.tap()
                } label: {
                    PrimaryButtonLabel(title: loc("reactivate"), icon: "arrow.counterclockwise")
                }
                .buttonStyle(.plain)
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label(loc("delete"), systemImage: "trash")
                        .font(.headline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .glassBackground(in: Capsule(), interactive: true)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }

    private func markCancelled(_ sub: Subscription) {
        store.cancel(sub.id)
        Haptics.success()
        confetti += 1
        withAnimation(.snappy) {
            celebration = loc("celebrate_text", L10n.money(sub.yearlyCost))
        }
        if !reviewRequested {
            reviewRequested = true
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                requestReview()
            }
        }
    }
}
