//
//  Localization.swift
//  Textes dans la langue de l'iPhone (français, anglais, espagnol, allemand, italien),
//  montants dans la devise choisie, dates.
//
//  Usage dans les écrans : loc("home_title")  ou  loc("summary_active", 4)
//  Les traductions sont dans Strings.swift.
//

import Foundation

nonisolated enum L10n {
    static let supportedLanguages = ["fr", "en", "es", "de", "it"]

    /// Langue utilisée par l'app (la première langue de l'iPhone qu'on sait parler, sinon anglais).
    static let language: String = {
        for preferred in Locale.preferredLanguages {
            let code = String(preferred.prefix(2))
            if supportedLanguages.contains(code) { return code }
        }
        return "en"
    }()

    /// Texte traduit. Les {0}, {1}… sont remplacés par les valeurs données.
    static func t(_ key: String, _ args: CustomStringConvertible...) -> String {
        var text = Strings.table(for: language)[key] ?? Strings.en[key] ?? key
        for (index, value) in args.enumerated() {
            text = text.replacingOccurrences(of: "{\(index)}", with: value.description)
        }
        return text
    }

    // MARK: Argent

    /// Devises proposées dans les Réglages.
    static let currencies = ["EUR", "USD", "GBP", "CHF", "CAD", "AUD", "JPY", "SEK", "NOK", "DKK",
                             "PLN", "CZK", "MAD", "XOF", "TND", "DZD", "BRL", "MXN", "INR", "TRY"]

    /// Devise de la région de l'iPhone (ex : EUR en France).
    static var defaultCurrency: String {
        let code = Locale.current.currency?.identifier ?? "EUR"
        return code.isEmpty ? "EUR" : code
    }

    /// Devise choisie dans les Réglages.
    static var currencyCode: String {
        let saved = UserDefaults.standard.string(forKey: SettingsKey.currency) ?? ""
        return saved.isEmpty ? defaultCurrency : saved
    }

    /// Nom d'une devise : "Euro (EUR)"
    static func currencyName(_ code: String) -> String {
        let name = Locale(identifier: language).localizedString(forCurrencyCode: code) ?? code
        return "\(name.prefix(1).uppercased())\(name.dropFirst()) (\(code))"
    }

    /// Symbole de la devise choisie : "€"
    static var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale.current
        return formatter.currencySymbol ?? currencyCode
    }

    /// "9,99 €"
    static func money(_ value: Double) -> String {
        value.formatted(.currency(code: currencyCode).locale(Locale.current))
    }

    /// "1,2 k €" pour les axes des graphiques.
    static func compactMoney(_ value: Double) -> String {
        if value >= 1000 {
            let short = (value / 1000).formatted(.number.precision(.fractionLength(0...1)))
            return "\(short) k \(currencySymbol)"
        }
        return "\(Int(value.rounded())) \(currencySymbol)"
    }

    // MARK: Dates

    private static func formatter(_ template: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language)
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter
    }

    private static let shortFormatter = formatter("d MMM")
    private static let longFormatter = formatter("EEEE d MMMM yyyy")
    private static let monthFormatter = formatter("MMMM yyyy")
    private static let monthShortFormatter = formatter("MMM")

    /// "12 mars"
    static func shortDate(_ date: Date) -> String { shortFormatter.string(from: date) }

    /// "Mercredi 12 mars 2027"
    static func longDate(_ date: Date) -> String { capitalized(longFormatter.string(from: date)) }

    /// "Novembre 2026"
    static func monthTitle(_ date: Date) -> String { capitalized(monthFormatter.string(from: date)) }

    /// "Nov."
    static func monthShort(_ date: Date) -> String { capitalized(monthShortFormatter.string(from: date)) }

    /// Nombre de jours entre aujourd'hui et une date (0 = aujourd'hui).
    static func daysUntil(_ date: Date, from now: Date = .now) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day ?? 0
    }

    /// "Aujourd'hui", "Demain", "Dans 5 j", ou "12 mars" au-delà d'un mois.
    static func relativeDay(_ date: Date) -> String {
        let days = daysUntil(date)
        switch days {
        case 0: return t("day_today")
        case 1: return t("day_tomorrow")
        case 2...31: return t("day_in", days)
        default: return shortDate(date)
        }
    }

    private static func capitalized(_ text: String) -> String {
        "\(text.prefix(1).uppercased())\(text.dropFirst())"
    }
}

/// Raccourci utilisé dans les écrans.
func loc(_ key: String, _ args: CustomStringConvertible...) -> String {
    var text = L10n.t(key)
    for (index, value) in args.enumerated() {
        text = text.replacingOccurrences(of: "{\(index)}", with: value.description)
    }
    return text
}
