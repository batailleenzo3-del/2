//
//  ContentView.swift
//  Écran racine : tutoriel → onglets (Abonnements, Calendrier, Stats).
//

import SwiftUI
import Combine

enum AppTab: Hashable {
    case home, calendar, stats
}

struct ContentView: View {
    @StateObject private var store = SubscriptionStore()
    @StateObject private var purchases = PurchaseManager()
    @AppStorage(SettingsKey.onboardingDone) private var onboardingDone = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: AppTab = .home

    var body: some View {
        ZStack {
            AppBackground()

            if !onboardingDone {
                OnboardingView {
                    withAnimation(.snappy) { onboardingDone = true }
                }
                .transition(.opacity)
            } else {
                TabView(selection: $tab) {
                    HomeView(store: store, purchases: purchases)
                        .tabItem { Label(loc("tab_home"), systemImage: "square.stack.fill") }
                        .tag(AppTab.home)
                    CalendarScreen(store: store)
                        .tabItem { Label(loc("tab_calendar"), systemImage: "calendar") }
                        .tag(AppTab.calendar)
                    StatsScreen(store: store)
                        .tabItem { Label(loc("tab_stats"), systemImage: "chart.pie.fill") }
                        .tag(AppTab.stats)
                }
                .minimizeTabBarOnScroll()
            }
        }
        .appAppearance()
        .task { await store.refresh() }
        .onChange(of: scenePhase) { _, phase in
            // Les dates avancent : on recalcule les prochains prélèvements et les rappels.
            if phase == .active {
                Task { await store.refresh() }
            }
        }
    }
}

private extension View {
    /// iOS 26 : la barre d'onglets Liquid Glass se réduit quand on fait défiler.
    @ViewBuilder
    func minimizeTabBarOnScroll() -> some View {
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }
}

#Preview {
    ContentView()
}
