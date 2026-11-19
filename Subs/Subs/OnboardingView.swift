//
//  OnboardingView.swift
//  Tutoriel du premier lancement (4 pages).
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.appTheme) private var theme
    let onFinish: () -> Void
    @State private var page = 0

    private struct Page {
        let icon: String
        let color: Color
        let titleKey: String
        let textKey: String
    }

    private let pages: [Page] = [
        Page(icon: "creditcard.and.123", color: .green, titleKey: "onb1_title", textKey: "onb1_text"),
        Page(icon: "bell.badge.fill", color: .orange, titleKey: "onb2_title", textKey: "onb2_text"),
        Page(icon: "hourglass", color: .purple, titleKey: "onb3_title", textKey: "onb3_text"),
        Page(icon: "lock.shield.fill", color: .blue, titleKey: "onb4_title", textKey: "onb4_text")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if page < pages.count - 1 {
                    Button(loc("skip")) { onFinish() }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }
            }
            .frame(height: 44)

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index], index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if page < pages.count - 1 {
                    withAnimation(.snappy) { page += 1 }
                } else {
                    onFinish()
                }
            } label: {
                PrimaryButtonLabel(title: page < pages.count - 1 ? loc("next") : loc("start"))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
            .frame(maxWidth: 520)
        }
    }

    private func pageView(_ item: Page, index: Int) -> some View {
        VStack(spacing: 26) {
            Spacer()
            if index == 0 {
                demoCard
            } else {
                Image(systemName: item.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(item.color)
                    .frame(width: 150, height: 150)
                    .glassBackground(in: Circle())
            }
            VStack(spacing: 12) {
                Text(loc(item.titleKey))
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(loc(item.textKey))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: 560)
    }

    /// Mini aperçu de l'app : un total et trois abonnements qui apparaissent.
    private var demoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(loc("summary_per_month"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(L10n.money(37.47))
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.diagonalGradient)
            demoRow("play.tv.fill", SubPalette.color(0), loc("catg_video"), 13.49, delay: 0)
            demoRow("music.note", SubPalette.color(3), loc("catg_music"), 11.99, delay: 0.15)
            demoRow("dumbbell.fill", SubPalette.color(1), loc("catg_fitness"), 11.99, delay: 0.3)
        }
        .padding(18)
        .frame(width: 270)
        .glassBackground(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: theme.secondary.opacity(0.25), radius: 24, y: 12)
    }

    private func demoRow(_ symbol: String, _ color: Color, _ name: String, _ price: Double, delay: Double) -> some View {
        HStack(spacing: 10) {
            SubIconView(name: name, color: color, symbol: symbol, size: 32)
            Text(name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Spacer()
            Text(L10n.money(price))
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
        }
        .phaseAnimator([false, true]) { content, highlighted in
            content.scaleEffect(highlighted ? 1.03 : 1, anchor: .leading)
        } animation: { _ in
            .easeInOut(duration: 1.2).delay(delay)
        }
    }
}
