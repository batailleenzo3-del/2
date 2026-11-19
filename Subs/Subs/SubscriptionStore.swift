//
//  SubscriptionStore.swift
//  La logique : liste des abonnements, sauvegarde sur l'iPhone, totaux, calendrier, rappels.
//  Les données sont dans un fichier JSON local (sauvegardé avec la sauvegarde iCloud/ordinateur
//  de l'iPhone). Rien n'est envoyé sur internet.
//

import Foundation
import Combine
import SwiftUI
import UserNotifications

@MainActor
final class SubscriptionStore: ObservableObject {
    @Published private(set) var subscriptions: [Subscription] = []
    @Published private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined

    private let fileURL: URL

    init() {
        let base = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                 appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
        fileURL = base.appendingPathComponent("subscriptions.json")
        load()
    }

    // MARK: Listes

    var active: [Subscription] { subscriptions.filter(\.isActive) }

    var cancelled: [Subscription] {
        subscriptions.filter { !$0.isActive }
            .sorted { ($0.cancelledDate ?? .distantPast) > ($1.cancelledDate ?? .distantPast) }
    }

    func subscription(_ id: UUID) -> Subscription? {
        subscriptions.first { $0.id == id }
    }

    func sorted(_ list: [Subscription], by sort: ListSort) -> [Subscription] {
        switch sort {
        case .nextPayment:
            return list.sorted { ($0.nextPayment() ?? .distantFuture) < ($1.nextPayment() ?? .distantFuture) }
        case .price:
            return list.sorted { $0.monthlyCost > $1.monthlyCost }
        case .name:
            return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    /// Prélèvements des `days` prochains jours, du plus proche au plus lointain.
    func upcoming(withinDays days: Int) -> [UpcomingPayment] {
        let now = Date.now
        guard let end = Calendar.current.date(byAdding: .day, value: days, to: now) else { return [] }
        return active
            .flatMap { sub in sub.payments(from: now, through: end).map { UpcomingPayment(subscription: sub, date: $0) } }
            .sorted { $0.date < $1.date }
    }

    /// Essais gratuits qui se terminent dans les `days` prochains jours.
    func trialsEndingSoon(days: Int = 7) -> [Subscription] {
        active
            .filter { $0.isInTrial() && L10n.daysUntil($0.anchorDate) <= days }
            .sorted { $0.anchorDate < $1.anchorDate }
    }

    // MARK: Totaux

    var monthlyTotal: Double { active.reduce(0) { $0 + $1.monthlyCost } }
    var yearlyTotal: Double { active.reduce(0) { $0 + $1.yearlyCost } }
    var dailyTotal: Double { yearlyTotal / 365 }

    /// Argent économisé depuis les résiliations.
    var totalSaved: Double { subscriptions.reduce(0) { $0 + $1.savedSinceCancellation() } }

    /// Ce que les abonnements résiliés auraient coûté sur un an.
    var yearlySavedProjection: Double { cancelled.reduce(0) { $0 + $1.yearlyCost } }

    /// Prélèvements d'un mois, regroupés par jour.
    func payments(inMonthOf month: Date) -> [Date: [Subscription]] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [:] }
        let end = interval.end.addingTimeInterval(-1)
        var result: [Date: [Subscription]] = [:]
        for sub in subscriptions {
            for date in sub.payments(from: interval.start, through: end) {
                result[calendar.startOfDay(for: date), default: []].append(sub)
            }
        }
        return result
    }

    /// Total réellement prélevé (ta part) sur un mois.
    func total(inMonthOf month: Date) -> Double {
        payments(inMonthOf: month).values.joined().reduce(0) { $0 + $1.share }
    }

    /// Totaux des `count` prochains mois (mois en cours compris).
    func nextMonthsTotals(_ count: Int) -> [MonthTotal] {
        let calendar = Calendar.current
        guard let start = calendar.dateInterval(of: .month, for: .now)?.start else { return [] }
        return (0..<count).compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: offset, to: start) else { return nil }
            return MonthTotal(month: month, amount: total(inMonthOf: month))
        }
    }

    /// Coût mensuel par catégorie, de la plus chère à la moins chère.
    func monthlyByCategory() -> [CategoryShare] {
        var totals: [SubCategory: Double] = [:]
        for sub in active { totals[sub.category, default: 0] += sub.monthlyCost }
        return totals
            .filter { $0.value > 0 }
            .map { CategoryShare(category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    // MARK: Version gratuite

    func canAdd(isPro: Bool) -> Bool {
        isPro || active.count < AppConfig.freeSubscriptionLimit
    }

    var freeSlotsLeft: Int { max(0, AppConfig.freeSubscriptionLimit - active.count) }

    // MARK: Modifications

    func add(_ subscription: Subscription) {
        subscriptions.append(subscription)
        save()
        // Première fois : on demande l'autorisation des notifications, au moment où elle a du sens.
        if subscription.reminderDays >= 0 && notificationStatus == .notDetermined {
            Task {
                _ = await NotificationService.requestAuthorization()
                await refreshNotificationStatus()
                rescheduleNotifications()
            }
        }
    }

    func update(_ subscription: Subscription) {
        guard let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) else { return }
        subscriptions[index] = subscription
        save()
    }

    func delete(_ id: UUID) {
        subscriptions.removeAll { $0.id == id }
        save()
    }

    func cancel(_ id: UUID) {
        guard let index = subscriptions.firstIndex(where: { $0.id == id }) else { return }
        subscriptions[index].cancelledDate = .now
        save()
    }

    func reactivate(_ id: UUID) {
        guard let index = subscriptions.firstIndex(where: { $0.id == id }) else { return }
        subscriptions[index].cancelledDate = nil
        save()
    }

    /// Les dates avancent avec le temps : à appeler quand l'app revient au premier plan.
    func refresh() async {
        await refreshNotificationStatus()
        rescheduleNotifications()
        objectWillChange.send()
    }

    /// Après un changement de devise, d'heure de rappel…
    func settingsChanged() {
        rescheduleNotifications()
        objectWillChange.send()
    }

    func refreshNotificationStatus() async {
        notificationStatus = await NotificationService.status()
    }

    func requestNotifications() async {
        _ = await NotificationService.requestAuthorization()
        await refreshNotificationStatus()
        rescheduleNotifications()
    }

    var hasReminders: Bool { active.contains { $0.reminderDays >= 0 } }

    func rescheduleNotifications() {
        NotificationService.reschedule(subscriptions)
    }

    // MARK: Sauvegarde

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let list = try? decoder.decode([Subscription].self, from: data) {
            subscriptions = list
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(subscriptions) {
            try? data.write(to: fileURL, options: [.atomic])
        }
        rescheduleNotifications()
    }

    // MARK: Export

    /// Fichier CSV (ouvrable dans Numbers, Excel, Google Sheets).
    func exportCSV() -> URL {
        func field(_ text: String) -> String {
            "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let price: (Double) -> String = { String(format: "%.2f", $0) }

        var lines = ["name;price;your_share;currency;cycle;next_payment;monthly_cost;yearly_cost;category;shared_with;free_trial;status;cancelled_on;notes"]
        for sub in sorted(subscriptions, by: .name) {
            lines.append([
                field(sub.name),
                price(sub.price),
                price(sub.share),
                L10n.currencyCode,
                sub.cycle.rawValue,
                sub.nextPayment().map { dateFormatter.string(from: $0) } ?? "",
                price(sub.monthlyCost),
                price(sub.yearlyCost),
                sub.category.rawValue,
                "\(sub.sharedWith)",
                sub.isTrial ? "yes" : "no",
                sub.isActive ? "active" : "cancelled",
                sub.cancelledDate.map { dateFormatter.string(from: $0) } ?? "",
                field(sub.notes)
            ].joined(separator: ";"))
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Subs.csv")
        try? lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: Tests

    #if DEBUG
    /// Ajoute des exemples pour tester l'app et faire des captures d'écran.
    func debugAddSamples() {
        let calendar = Calendar.current
        func day(_ offset: Int) -> Date {
            calendar.startOfDay(for: calendar.date(byAdding: .day, value: offset, to: .now) ?? .now)
        }
        let samples: [Subscription] = [
            Subscription(name: "Netflix", price: 13.49, anchorDate: day(2), category: .video, colorIndex: 0,
                         manageURL: "https://www.netflix.com/cancelplan"),
            Subscription(name: "Spotify", price: 11.12, anchorDate: day(9), category: .music, colorIndex: 3),
            Subscription(name: "iCloud+", price: 2.99, anchorDate: day(15), category: .cloud, colorIndex: 6,
                         symbol: "icloud.fill", billedByApple: true),
            Subscription(name: "Disney+", price: 9.99, anchorDate: day(4), isTrial: true, category: .video, colorIndex: 7),
            Subscription(name: L10n.t("preset_gym"), price: 29.99, anchorDate: day(21), category: .fitness,
                         colorIndex: 1, symbol: "dumbbell.fill"),
            Subscription(name: "Microsoft 365", price: 99, cycle: .yearly, anchorDate: day(120), category: .software,
                         colorIndex: 1, sharedWith: 3),
            Subscription(name: L10n.t("preset_phone"), price: 15.99, anchorDate: day(6), category: .phone,
                         colorIndex: 3, symbol: "antenna.radiowaves.left.and.right"),
            Subscription(name: "Deezer", price: 11.99, anchorDate: day(-100), category: .music, colorIndex: 8,
                         cancelledDate: day(-75))
        ]
        subscriptions.append(contentsOf: samples)
        save()
    }

    func debugRemoveAll() {
        subscriptions.removeAll()
        save()
    }
    #endif
}
