//
//  Components.swift
//  Petits éléments réutilisés partout : icône d'abonnement, ligne de liste, bouton principal, vibrations.
//

import SwiftUI
import UIKit

// MARK: - Icône d'un abonnement

struct SubIconView: View {
    let name: String
    let color: Color
    let symbol: String?
    var size: CGFloat = 44

    private var initial: String {
        let letter = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)).uppercased()
        return letter.isEmpty ? "?" : letter
    }

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(LinearGradient(colors: [color, color.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size)
            .overlay {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: size * 0.42, weight: .semibold))
                        .foregroundStyle(.white)
                } else {
                    Text(initial)
                        .font(.system(size: size * 0.48, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .shadow(color: color.opacity(0.35), radius: size * 0.12, y: size * 0.06)
            .accessibilityHidden(true)
    }
}

struct SubIcon: View {
    let subscription: Subscription
    var size: CGFloat = 44

    var body: some View {
        SubIconView(name: subscription.name, color: subscription.color, symbol: subscription.symbol, size: size)
    }
}

// MARK: - Ligne de liste

struct SubscriptionRow: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: 14) {
            SubIcon(subscription: subscription, size: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text(subscription.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(detailLine)
                    .font(.footnote)
                    .foregroundStyle(subscription.isInTrial() ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                Text(L10n.money(subscription.share))
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                Text(subscription.cycle.perTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .glassBackground(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var detailLine: String {
        if !subscription.isActive {
            return loc("row_cancelled", L10n.money(subscription.savedSinceCancellation()))
        }
        if subscription.isInTrial() {
            return loc("row_trial", L10n.relativeDay(subscription.anchorDate))
        }
        guard let next = subscription.nextPayment() else { return subscription.cycle.title }
        return "\(subscription.cycle.title) · \(L10n.relativeDay(next))"
    }
}

// MARK: - Bouton principal (dégradé)

struct PrimaryButtonLabel: View {
    @Environment(\.appTheme) private var theme
    let title: String
    var icon: String? = nil
    var isLoading = false

    var body: some View {
        HStack(spacing: 8) {
            if isLoading { ProgressView().tint(.white) }
            if let icon { Image(systemName: icon) }
            Text(title)
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(theme.gradient, in: Capsule())
        .foregroundStyle(.white)
    }
}

// MARK: - Titre de section

struct SectionTitle: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.bold())
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Carte en verre

extension View {
    /// Carte en verre pleine largeur.
    func glassCard(cornerRadius: CGFloat = 26, padding: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassBackground(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Vibrations

enum Haptics {
    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: SettingsKey.haptics) as? Bool ?? true
    }

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
