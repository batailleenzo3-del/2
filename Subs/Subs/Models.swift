//
//  Models.swift
//  Les types de données (abonnement, fréquence, catégorie…) et les réglages.
//

import Foundation
import SwiftUI

// MARK: - Réglages (clés de sauvegarde)

nonisolated enum SettingsKey {
    static let onboardingDone = "settings.onboardingDone"
    static let appearance = "settings.appearance"
    static let haptics = "settings.haptics"
    static let reviewRequested = "settings.reviewRequested"
    static let theme = "settings.theme"
    static let glassLevel = "settings.glassLevel"
    static let currency = "settings.currency"
    static let reminderHour = "settings.reminderHour"
    static let reminderMinute = "settings.reminderMinute"
    static let defaultReminder = "settings.defaultReminder"
    static let listSort = "settings.listSort"
    static let yearlyMode = "settings.yearlyMode"
}

/// Thème clair / sombre.
nonisolated enum AppearanceOption: String, CaseIterable, Identifiable, Sendable {
    case system, light, dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return L10n.t("appearance_system")
        case .light: return L10n.t("appearance_light")
        case .dark: return L10n.t("appearance_dark")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Ordre de la liste des abonnements.
nonisolated enum ListSort: String, CaseIterable, Identifiable, Sendable {
    case nextPayment, price, name

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nextPayment: return L10n.t("sort_next")
        case .price: return L10n.t("sort_price")
        case .name: return L10n.t("sort_name")
        }
    }
}

// MARK: - Fréquence de paiement

nonisolated enum BillingCycle: String, CaseIterable, Identifiable, Codable, Sendable {
    case weekly, monthly, quarterly, semiannual, yearly

    var id: String { rawValue }

    /// "Mensuel"
    var title: String { L10n.t("cycle_\(rawValue)") }

    /// "/ mois"
    var perTitle: String { L10n.t("per_\(rawValue)") }

    var paymentsPerYear: Double {
        switch self {
        case .weekly: return 52
        case .monthly: return 12
        case .quarterly: return 4
        case .semiannual: return 2
        case .yearly: return 1
        }
    }

    /// Date du n-ième prélèvement après `date` (calculé depuis la date de départ :
    /// un abonnement du 31 tombe le 28/29 en février puis revient au 31 en mars).
    func date(byAdding count: Int, to date: Date, calendar: Calendar) -> Date? {
        switch self {
        case .weekly: return calendar.date(byAdding: .day, value: 7 * count, to: date)
        case .monthly: return calendar.date(byAdding: .month, value: count, to: date)
        case .quarterly: return calendar.date(byAdding: .month, value: 3 * count, to: date)
        case .semiannual: return calendar.date(byAdding: .month, value: 6 * count, to: date)
        case .yearly: return calendar.date(byAdding: .year, value: count, to: date)
        }
    }
}

// MARK: - Rappel

nonisolated enum ReminderOption: Int, CaseIterable, Identifiable, Sendable {
    case none = -1, sameDay = 0, oneDay = 1, twoDays = 2, threeDays = 3, oneWeek = 7

    var id: Int { rawValue }

    var title: String { Self.title(for: rawValue) }

    static func title(for days: Int) -> String {
        switch days {
        case ..<0: return L10n.t("reminder_none")
        case 0: return L10n.t("reminder_same_day")
        case 1: return L10n.t("reminder_one_day")
        case 7: return L10n.t("reminder_week")
        default: return L10n.t("reminder_days", days)
        }
    }

    /// Rappel proposé par défaut pour un nouvel abonnement (Réglages).
    static var defaultDays: Int {
        UserDefaults.standard.object(forKey: SettingsKey.defaultReminder) as? Int ?? 1
    }
}

// MARK: - Catégorie

nonisolated enum SubCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case video, music, gaming, cloud, software, ai, news, fitness, education, phone, internet, home, insurance, transport, other

    var id: String { rawValue }

    var title: String { L10n.t("catg_\(rawValue)") }

    var icon: String {
        switch self {
        case .video: return "play.tv.fill"
        case .music: return "music.note"
        case .gaming: return "gamecontroller.fill"
        case .cloud: return "icloud.fill"
        case .software: return "square.stack.3d.up.fill"
        case .ai: return "sparkles"
        case .news: return "newspaper.fill"
        case .fitness: return "dumbbell.fill"
        case .education: return "graduationcap.fill"
        case .phone: return "antenna.radiowaves.left.and.right"
        case .internet: return "wifi"
        case .home: return "house.fill"
        case .insurance: return "checkmark.shield.fill"
        case .transport: return "tram.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .video: return Color(red: 0.93, green: 0.23, blue: 0.27)
        case .music: return Color(red: 0.98, green: 0.30, blue: 0.55)
        case .gaming: return Color(red: 0.55, green: 0.36, blue: 0.96)
        case .cloud: return Color(red: 0.20, green: 0.60, blue: 1.00)
        case .software: return Color(red: 0.36, green: 0.42, blue: 0.95)
        case .ai: return Color(red: 0.10, green: 0.74, blue: 0.70)
        case .news: return Color(red: 0.55, green: 0.57, blue: 0.62)
        case .fitness: return Color(red: 1.00, green: 0.55, blue: 0.15)
        case .education: return Color(red: 0.98, green: 0.78, blue: 0.20)
        case .phone: return Color(red: 0.16, green: 0.78, blue: 0.45)
        case .internet: return Color(red: 0.00, green: 0.66, blue: 0.86)
        case .home: return Color(red: 0.80, green: 0.55, blue: 0.35)
        case .insurance: return Color(red: 0.30, green: 0.50, blue: 0.70)
        case .transport: return Color(red: 0.95, green: 0.40, blue: 0.20)
        case .other: return Color(red: 0.62, green: 0.64, blue: 0.70)
        }
    }
}

// MARK: - Couleurs des icônes

nonisolated enum SubPalette {
    static let colors: [Color] = [
        Color(red: 0.90, green: 0.07, blue: 0.13),  // rouge
        Color(red: 1.00, green: 0.45, blue: 0.15),  // orange
        Color(red: 0.98, green: 0.74, blue: 0.10),  // jaune
        Color(red: 0.11, green: 0.73, blue: 0.33),  // vert
        Color(red: 0.06, green: 0.64, blue: 0.56),  // sarcelle
        Color(red: 0.00, green: 0.66, blue: 0.88),  // cyan
        Color(red: 0.13, green: 0.42, blue: 0.96),  // bleu
        Color(red: 0.25, green: 0.22, blue: 0.75),  // indigo
        Color(red: 0.58, green: 0.27, blue: 0.95),  // violet
        Color(red: 0.98, green: 0.20, blue: 0.48),  // rose
        Color(red: 0.45, green: 0.47, blue: 0.53),  // gris
        Color(red: 0.12, green: 0.12, blue: 0.15)   // noir
    ]

    static func color(_ index: Int) -> Color {
        colors[((index % colors.count) + colors.count) % colors.count]
    }

    /// Symboles proposés pour l'icône (nil = initiale du nom).
    static let symbols: [String] = [
        "play.tv.fill", "music.note", "gamecontroller.fill", "icloud.fill", "sparkles", "newspaper.fill",
        "dumbbell.fill", "figure.run", "antenna.radiowaves.left.and.right", "wifi", "bolt.fill", "house.fill",
        "checkmark.shield.fill", "car.fill", "tram.fill", "book.fill", "graduationcap.fill", "heart.fill",
        "cart.fill", "creditcard.fill", "film.fill", "headphones", "camera.fill", "pawprint.fill"
    ]
}

// MARK: - Abonnement

nonisolated struct Subscription: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    /// Prix total d'un prélèvement (avant partage).
    var price: Double
    var cycle: BillingCycle
    /// Date d'un prélèvement réel : sert de repère pour calculer tous les autres.
    /// Pour un essai gratuit, c'est le jour du premier prélèvement (= fin de l'essai).
    var anchorDate: Date
    var isTrial: Bool
    var category: SubCategory
    var colorIndex: Int
    /// Symbole SF de l'icône (nil = initiale du nom).
    var symbol: String?
    /// Jours avant le prélèvement pour le rappel (-1 = aucun rappel).
    var reminderDays: Int
    /// Nombre de personnes qui paient (1 = seul).
    var sharedWith: Int
    /// Payé via l'App Store (résiliation dans les réglages Apple).
    var billedByApple: Bool
    /// Lien pour gérer ou résilier l'abonnement.
    var manageURL: String
    var notes: String
    /// Date de résiliation (nil = actif).
    var cancelledDate: Date?
    var createdAt: Date

    init(id: UUID = UUID(), name: String, price: Double = 0, cycle: BillingCycle = .monthly,
         anchorDate: Date = Calendar.current.startOfDay(for: .now), isTrial: Bool = false,
         category: SubCategory = .other, colorIndex: Int = 6, symbol: String? = nil,
         reminderDays: Int = ReminderOption.defaultDays, sharedWith: Int = 1, billedByApple: Bool = false,
         manageURL: String = "", notes: String = "", cancelledDate: Date? = nil, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.price = price
        self.cycle = cycle
        self.anchorDate = anchorDate
        self.isTrial = isTrial
        self.category = category
        self.colorIndex = colorIndex
        self.symbol = symbol
        self.reminderDays = reminderDays
        self.sharedWith = sharedWith
        self.billedByApple = billedByApple
        self.manageURL = manageURL
        self.notes = notes
        self.cancelledDate = cancelledDate
        self.createdAt = createdAt
    }

    // Lecture tolérante : une future version pourra ajouter des champs sans casser les données.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        price = try c.decodeIfPresent(Double.self, forKey: .price) ?? 0
        cycle = (try? c.decodeIfPresent(BillingCycle.self, forKey: .cycle)) ?? .monthly
        anchorDate = try c.decodeIfPresent(Date.self, forKey: .anchorDate) ?? .now
        isTrial = try c.decodeIfPresent(Bool.self, forKey: .isTrial) ?? false
        category = (try? c.decodeIfPresent(SubCategory.self, forKey: .category)) ?? .other
        colorIndex = try c.decodeIfPresent(Int.self, forKey: .colorIndex) ?? 6
        symbol = try c.decodeIfPresent(String.self, forKey: .symbol)
        reminderDays = try c.decodeIfPresent(Int.self, forKey: .reminderDays) ?? 1
        sharedWith = try c.decodeIfPresent(Int.self, forKey: .sharedWith) ?? 1
        billedByApple = try c.decodeIfPresent(Bool.self, forKey: .billedByApple) ?? false
        manageURL = try c.decodeIfPresent(String.self, forKey: .manageURL) ?? ""
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        cancelledDate = try c.decodeIfPresent(Date.self, forKey: .cancelledDate)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
    }

    // MARK: Calculs

    var isActive: Bool { cancelledDate == nil }

    var color: Color { SubPalette.color(colorIndex) }

    /// Ce que l'utilisateur paie réellement à chaque prélèvement (sa part).
    var share: Double { price / Double(max(1, sharedWith)) }

    var monthlyCost: Double { share * cycle.paymentsPerYear / 12 }
    var yearlyCost: Double { share * cycle.paymentsPerYear }

    /// Essai gratuit pas encore terminé.
    func isInTrial(now: Date = .now) -> Bool {
        isTrial && isActive && L10n.daysUntil(anchorDate, from: now) >= 0
    }

    /// Tous les prélèvements entre deux dates (incluses).
    /// Après une résiliation, plus aucun prélèvement (sauf `ignoringCancellation`).
    func payments(from start: Date, through end: Date, ignoringCancellation: Bool = false) -> [Date] {
        let calendar = Calendar.current
        let anchor = calendar.startOfDay(for: anchorDate)
        let first = calendar.startOfDay(for: start)
        var last = calendar.startOfDay(for: end)
        if !ignoringCancellation, let cancelledDate {
            last = min(last, calendar.startOfDay(for: cancelledDate))
        }
        guard last >= first, last >= anchor else { return [] }

        var index = 0
        // On saute directement près de la date de début (plus rapide pour les vieux abonnements).
        if first > anchor {
            let days = calendar.dateComponents([.day], from: anchor, to: first).day ?? 0
            let periodDays = 365.25 / cycle.paymentsPerYear
            index = max(0, Int(Double(days) / periodDays) - 2)
        }

        var result: [Date] = []
        while index < 20_000 {
            guard let date = cycle.date(byAdding: index, to: anchor, calendar: calendar) else { break }
            if date > last { break }
            if date >= first { result.append(date) }
            index += 1
        }
        return result
    }

    /// Prochain prélèvement (aujourd'hui compris). nil si résilié.
    func nextPayment(after now: Date = .now) -> Date? {
        guard isActive else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let base = max(today, calendar.startOfDay(for: anchorDate))
        let horizon = cycle.date(byAdding: 1, to: base, calendar: calendar) ?? base
        return payments(from: today, through: horizon).first
    }

    /// Les `count` prochains prélèvements.
    func upcomingPayments(_ count: Int, from now: Date = .now) -> [Date] {
        guard count > 0, let next = nextPayment(after: now) else { return [] }
        let end = cycle.date(byAdding: count, to: next, calendar: .current) ?? next
        return Array(payments(from: next, through: end).prefix(count))
    }

    /// Argent qui n'a pas été prélevé grâce à la résiliation.
    func savedSinceCancellation(now: Date = .now) -> Double {
        guard let cancelledDate else { return 0 }
        let start = Calendar.current.date(byAdding: .day, value: 1, to: cancelledDate) ?? cancelledDate
        return Double(payments(from: start, through: now, ignoringCancellation: true).count) * share
    }

    /// Lien pour gérer / résilier (App Store ou site du service).
    var manageLink: URL? {
        if billedByApple { return URL(string: "https://apps.apple.com/account/subscriptions") }
        var text = manageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if !text.lowercased().hasPrefix("http") { text = "https://" + text }
        return URL(string: text)
    }
}

/// Un prélèvement à venir (pour les listes).
nonisolated struct UpcomingPayment: Identifiable, Sendable {
    let subscription: Subscription
    let date: Date
    var id: String { "\(subscription.id.uuidString)-\(Int(date.timeIntervalSince1970))" }
}

/// Dépense mensuelle d'une catégorie (graphique).
nonisolated struct CategoryShare: Identifiable, Sendable {
    let category: SubCategory
    let amount: Double
    var id: String { category.rawValue }
}

/// Total d'un mois (graphique).
nonisolated struct MonthTotal: Identifiable, Sendable {
    let month: Date
    let amount: Double
    var id: Date { month }
    var label: String { L10n.monthShort(month) }
}
