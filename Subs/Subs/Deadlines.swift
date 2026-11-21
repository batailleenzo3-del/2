//
//  Deadlines.swift
//  Les échéances (nouveau en 1.1) : papiers d'identité, contrôle technique, garanties,
//  bons d'achat, ordonnances… tout ce qui expire un jour. Subs prévient avant la date.
//

import Foundation
import SwiftUI

// MARK: - Type d'échéance

nonisolated enum DeadlineKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case identity, vehicle, home, health, warranty, voucher, contract, pet, other

    var id: String { rawValue }

    var title: String { L10n.t("dlk_\(rawValue)") }

    var icon: String {
        switch self {
        case .identity: return "person.text.rectangle.fill"
        case .vehicle: return "car.fill"
        case .home: return "house.fill"
        case .health: return "cross.case.fill"
        case .warranty: return "checkmark.shield.fill"
        case .voucher: return "giftcard.fill"
        case .contract: return "doc.text.fill"
        case .pet: return "pawprint.fill"
        case .other: return "hourglass"
        }
    }

    var color: Color {
        switch self {
        case .identity: return Color(red: 0.13, green: 0.42, blue: 0.96)
        case .vehicle: return Color(red: 0.95, green: 0.40, blue: 0.20)
        case .home: return Color(red: 0.80, green: 0.55, blue: 0.35)
        case .health: return Color(red: 0.93, green: 0.23, blue: 0.27)
        case .warranty: return Color(red: 0.06, green: 0.64, blue: 0.56)
        case .voucher: return Color(red: 0.98, green: 0.20, blue: 0.48)
        case .contract: return Color(red: 0.45, green: 0.47, blue: 0.53)
        case .pet: return Color(red: 0.58, green: 0.27, blue: 0.95)
        case .other: return Color(red: 0.98, green: 0.74, blue: 0.10)
        }
    }
}

// MARK: - Rappels d'une échéance (plusieurs possibles)

nonisolated enum DeadlineReminder {
    /// Jours avant la date proposés (on peut en cocher plusieurs).
    static let options = [0, 1, 3, 7, 14, 30, 60, 90]

    static let defaultDays = [30, 7]

    /// "Le jour J", "La veille", "7 j avant"…
    static func chip(_ days: Int) -> String {
        switch days {
        case 0: return L10n.t("dl_chip_day")
        case 1: return L10n.t("reminder_one_day")
        default: return L10n.t("dl_chip_days", days)
        }
    }
}

/// Renouvellement automatique proposé (en mois, 0 = aucun).
nonisolated enum DeadlineRenewal {
    static let options = [0, 6, 12, 24, 36, 60, 120]

    static func title(_ months: Int) -> String {
        switch months {
        case ..<1: return L10n.t("renew_none")
        case 12: return L10n.t("renew_year")
        case let m where m % 12 == 0: return L10n.t("renew_years", m / 12)
        default: return L10n.t("renew_months", months)
        }
    }
}

// MARK: - Échéance

nonisolated struct Deadline: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var kind: DeadlineKind
    /// Date d'expiration (ou de fin de garantie, de validité…).
    var date: Date
    /// Jours avant la date pour les rappels (vide = aucun rappel).
    var reminders: [Int]
    /// Durée proposée quand on renouvelle (en mois, 0 = on choisit la date à la main).
    var renewMonths: Int
    var notes: String
    /// Date où l'utilisateur a indiqué ne plus avoir besoin de suivre (nil = suivie).
    var doneDate: Date?
    var createdAt: Date

    init(id: UUID = UUID(), name: String, kind: DeadlineKind = .other,
         date: Date = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now),
         reminders: [Int] = DeadlineReminder.defaultDays, renewMonths: Int = 0, notes: String = "",
         doneDate: Date? = nil, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.kind = kind
        self.date = date
        self.reminders = reminders
        self.renewMonths = renewMonths
        self.notes = notes
        self.doneDate = doneDate
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        kind = (try? c.decodeIfPresent(DeadlineKind.self, forKey: .kind)) ?? .other
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? .now
        reminders = try c.decodeIfPresent([Int].self, forKey: .reminders) ?? DeadlineReminder.defaultDays
        renewMonths = try c.decodeIfPresent(Int.self, forKey: .renewMonths) ?? 0
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        doneDate = try c.decodeIfPresent(Date.self, forKey: .doneDate)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
    }

    var isActive: Bool { doneDate == nil }

    var color: Color { kind.color }

    /// Jours restants (négatif = expiré).
    var daysLeft: Int { L10n.daysUntil(date) }

    var isExpired: Bool { daysLeft < 0 }

    /// Couleur de l'état : rouge (expiré / < 7 j), orange (< 30 j), vert.
    var statusColor: Color {
        switch daysLeft {
        case ..<7: return .red
        case ..<30: return .orange
        default: return .green
        }
    }

    /// "Expiré depuis 3 j", "Expire aujourd'hui", "Dans 12 j", "12 mars 2027".
    var statusText: String {
        let days = daysLeft
        switch days {
        case ..<0: return L10n.t("dl_expired_since", -days)
        case 0: return L10n.t("dl_expires_today")
        case 1: return L10n.t("day_tomorrow")
        case 2...90: return L10n.t("day_in", days)
        default: return L10n.shortDate(date) + " " + String(Calendar.current.component(.year, from: date))
        }
    }

    /// Date proposée quand on renouvelle.
    var suggestedRenewalDate: Date {
        let calendar = Calendar.current
        let base = max(calendar.startOfDay(for: date), calendar.startOfDay(for: .now))
        let months = renewMonths > 0 ? renewMonths : 12
        return calendar.date(byAdding: .month, value: months, to: renewMonths > 0 ? date : base) ?? base
    }
}

// MARK: - Modèles proposés

nonisolated struct DeadlinePreset: Identifiable, Hashable, Sendable {
    let key: String
    let kind: DeadlineKind
    var reminders: [Int] = DeadlineReminder.defaultDays
    var renewMonths: Int = 0

    var id: String { key }
    var name: String { L10n.t("dlp_\(key)") }

    func makeDeadline() -> Deadline {
        Deadline(name: name, kind: kind, reminders: reminders, renewMonths: renewMonths)
    }
}

nonisolated enum DeadlineCatalog {
    /// Aucune durée de validité inventée : elles varient selon les pays.
    /// Seuls les entretiens annuels proposent un renouvellement (modifiable).
    static let presets: [DeadlinePreset] = [
        DeadlinePreset(key: "passport", kind: .identity, reminders: [180, 90, 30]),
        DeadlinePreset(key: "id_card", kind: .identity, reminders: [90, 30]),
        DeadlinePreset(key: "license", kind: .identity, reminders: [90, 30]),
        DeadlinePreset(key: "residence", kind: .identity, reminders: [90, 30]),
        DeadlinePreset(key: "visa", kind: .identity, reminders: [30, 7]),
        DeadlinePreset(key: "inspection", kind: .vehicle, reminders: [30, 7]),
        DeadlinePreset(key: "car_service", kind: .vehicle, reminders: [14], renewMonths: 12),
        DeadlinePreset(key: "tires", kind: .vehicle, reminders: [14]),
        DeadlinePreset(key: "boiler", kind: .home, reminders: [30], renewMonths: 12),
        DeadlinePreset(key: "chimney", kind: .home, reminders: [30], renewMonths: 12),
        DeadlinePreset(key: "smoke", kind: .home, reminders: [7]),
        DeadlinePreset(key: "lease", kind: .home, reminders: [90, 30]),
        DeadlinePreset(key: "prescription", kind: .health, reminders: [7, 1]),
        DeadlinePreset(key: "vaccine", kind: .health, reminders: [30]),
        DeadlinePreset(key: "lenses", kind: .health, reminders: [7]),
        DeadlinePreset(key: "health_card", kind: .health, reminders: [30]),
        DeadlinePreset(key: "warranty", kind: .warranty, reminders: [30]),
        DeadlinePreset(key: "phone_warranty", kind: .warranty, reminders: [30]),
        DeadlinePreset(key: "return", kind: .warranty, reminders: [3, 1]),
        DeadlinePreset(key: "gift_card", kind: .voucher, reminders: [30, 7]),
        DeadlinePreset(key: "voucher", kind: .voucher, reminders: [7, 1]),
        DeadlinePreset(key: "bank_card", kind: .voucher, reminders: [30]),
        DeadlinePreset(key: "commitment", kind: .contract, reminders: [30, 7]),
        DeadlinePreset(key: "contract_end", kind: .contract, reminders: [60, 30]),
        DeadlinePreset(key: "pet_vaccine", kind: .pet, reminders: [14], renewMonths: 12),
        DeadlinePreset(key: "pet_treatment", kind: .pet, reminders: [1])
    ]
}

// MARK: - Icône et ligne

struct DeadlineIcon: View {
    let kind: DeadlineKind
    var size: CGFloat = 44

    var body: some View {
        SubIconView(name: kind.title, color: kind.color, symbol: kind.icon, size: size)
    }
}

struct DeadlineRow: View {
    let deadline: Deadline

    var body: some View {
        HStack(spacing: 14) {
            DeadlineIcon(kind: deadline.kind, size: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text(deadline.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(L10n.longDate(deadline.date))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 8)
            if deadline.isActive {
                Text(deadline.statusText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(deadline.statusColor)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassBackground(in: Capsule(), tint: deadline.statusColor.opacity(0.18))
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
        }
        .padding(14)
        .glassBackground(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
