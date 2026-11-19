//
//  NotificationService.swift
//  Rappels avant chaque prélèvement et avant la fin des essais gratuits.
//  Notifications locales : programmées sur l'iPhone, aucun serveur.
//

import Foundation
import UserNotifications

nonisolated enum NotificationService {

    static func status() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Reprogramme tous les rappels. iOS limite à 64 notifications en attente par app :
    /// on garde les plus proches (les suivantes sont programmées à la prochaine ouverture).
    static func reschedule(_ subscriptions: [Subscription]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let calendar = Calendar.current
        let defaults = UserDefaults.standard
        let hour = defaults.object(forKey: SettingsKey.reminderHour) as? Int ?? AppConfig.defaultReminderHour
        let minute = defaults.object(forKey: SettingsKey.reminderMinute) as? Int ?? 0
        let now = Date.now

        var items: [(fire: Date, sub: Subscription, payment: Date)] = []
        for sub in subscriptions where sub.isActive && sub.reminderDays >= 0 {
            for payment in sub.upcomingPayments(4, from: now) {
                guard let day = calendar.date(byAdding: .day, value: -sub.reminderDays, to: payment),
                      let fire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                      fire > now else { continue }
                items.append((fire: fire, sub: sub, payment: payment))
            }
        }
        items.sort { $0.fire < $1.fire }

        for item in items.prefix(AppConfig.maxScheduledNotifications) {
            let content = makeContent(item.sub, payment: item.payment, daysBefore: item.sub.reminderDays)
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: item.fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "\(item.sub.id.uuidString)-\(Int(item.payment.timeIntervalSince1970))"
            center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }
    }

    static func makeContent(_ sub: Subscription, payment: Date, daysBefore: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let when: String
        switch daysBefore {
        case ...0: when = L10n.t("notif_when_today")
        case 1: when = L10n.t("notif_when_tomorrow")
        default: when = L10n.t("notif_when_days", daysBefore)
        }
        let price = L10n.money(sub.share)
        let isTrialEnd = sub.isTrial && Calendar.current.isDate(payment, inSameDayAs: sub.anchorDate)
        if isTrialEnd {
            content.title = L10n.t("notif_trial_title", sub.name)
            content.body = L10n.t("notif_trial_body", when, price)
        } else {
            content.title = L10n.t("notif_payment_title", sub.name, price)
            content.body = L10n.t("notif_payment_body", when)
        }
        content.sound = .default
        return content
    }

    #if DEBUG
    /// Envoie une notification d'exemple dans 5 secondes (pour tester).
    static func sendTest(_ sub: Subscription?) {
        let content: UNMutableNotificationContent
        if let sub {
            content = makeContent(sub, payment: sub.nextPayment() ?? .now, daysBefore: 1)
        } else {
            content = UNMutableNotificationContent()
            content.title = "Subs"
            content.body = "Test"
            content.sound = .default
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "test-\(UUID().uuidString)",
                                                                     content: content, trigger: trigger))
    }
    #endif
}
