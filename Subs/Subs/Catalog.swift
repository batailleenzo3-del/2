//
//  Catalog.swift
//  Services proposés quand on ajoute un abonnement. Aucun prix n'est pré-rempli :
//  les tarifs changent selon le pays et l'offre, l'utilisateur saisit le sien (le vrai).
//

import Foundation

nonisolated struct ServicePreset: Identifiable, Hashable, Sendable {
    let name: String
    let category: SubCategory
    let colorIndex: Int
    var symbol: String? = nil
    var cycle: BillingCycle = .monthly
    var billedByApple: Bool = false
    var manageURL: String = ""

    var id: String { name }

    func makeSubscription() -> Subscription {
        Subscription(name: name, cycle: cycle, category: category, colorIndex: colorIndex, symbol: symbol,
                     billedByApple: billedByApple, manageURL: manageURL)
    }
}

nonisolated enum Catalog {
    static let presets: [ServicePreset] = [
        // Vidéo
        ServicePreset(name: "Netflix", category: .video, colorIndex: 0, manageURL: "https://www.netflix.com/cancelplan"),
        ServicePreset(name: "Disney+", category: .video, colorIndex: 7, manageURL: "https://www.disneyplus.com/account"),
        ServicePreset(name: "Prime Video", category: .video, colorIndex: 5),
        ServicePreset(name: "YouTube Premium", category: .video, colorIndex: 0, manageURL: "https://www.youtube.com/paid_memberships"),
        ServicePreset(name: "Apple TV", category: .video, colorIndex: 11, billedByApple: true),
        ServicePreset(name: "Canal+", category: .video, colorIndex: 11),
        ServicePreset(name: "Max", category: .video, colorIndex: 6),
        ServicePreset(name: "Paramount+", category: .video, colorIndex: 6),
        ServicePreset(name: "Crunchyroll", category: .video, colorIndex: 1),
        ServicePreset(name: "Twitch", category: .video, colorIndex: 8),
        // Musique
        ServicePreset(name: "Spotify", category: .music, colorIndex: 3, manageURL: "https://www.spotify.com/account/subscription/"),
        ServicePreset(name: "Apple Music", category: .music, colorIndex: 9, billedByApple: true),
        ServicePreset(name: "Deezer", category: .music, colorIndex: 8),
        ServicePreset(name: "Audible", category: .music, colorIndex: 1),
        // Jeux
        ServicePreset(name: "Xbox Game Pass", category: .gaming, colorIndex: 3, manageURL: "https://account.microsoft.com/services"),
        ServicePreset(name: "PlayStation Plus", category: .gaming, colorIndex: 6),
        ServicePreset(name: "Nintendo Switch Online", category: .gaming, colorIndex: 0, cycle: .yearly),
        ServicePreset(name: "Apple Arcade", category: .gaming, colorIndex: 0, billedByApple: true),
        // Cloud
        ServicePreset(name: "iCloud+", category: .cloud, colorIndex: 6, symbol: "icloud.fill", billedByApple: true),
        ServicePreset(name: "Apple One", category: .cloud, colorIndex: 11, billedByApple: true),
        ServicePreset(name: "Google One", category: .cloud, colorIndex: 6),
        ServicePreset(name: "Dropbox", category: .cloud, colorIndex: 6, manageURL: "https://www.dropbox.com/account/plan"),
        // Logiciels
        ServicePreset(name: "Microsoft 365", category: .software, colorIndex: 1, cycle: .yearly, manageURL: "https://account.microsoft.com/services"),
        ServicePreset(name: "Adobe Creative Cloud", category: .software, colorIndex: 0, manageURL: "https://account.adobe.com/plans"),
        ServicePreset(name: "Canva", category: .software, colorIndex: 5),
        ServicePreset(name: "Notion", category: .software, colorIndex: 11),
        // IA
        ServicePreset(name: "ChatGPT Plus", category: .ai, colorIndex: 4),
        ServicePreset(name: "Claude Pro", category: .ai, colorIndex: 1),
        ServicePreset(name: "Gemini", category: .ai, colorIndex: 6),
        // Presse
        ServicePreset(name: L10n.t("preset_newspaper"), category: .news, colorIndex: 10, symbol: "newspaper.fill"),
        // Sport
        ServicePreset(name: L10n.t("preset_gym"), category: .fitness, colorIndex: 1, symbol: "dumbbell.fill"),
        ServicePreset(name: "Strava", category: .fitness, colorIndex: 1),
        // Apprendre
        ServicePreset(name: "Duolingo", category: .education, colorIndex: 3),
        // Téléphone & internet
        ServicePreset(name: L10n.t("preset_phone"), category: .phone, colorIndex: 3, symbol: "antenna.radiowaves.left.and.right"),
        ServicePreset(name: L10n.t("preset_internet"), category: .internet, colorIndex: 5, symbol: "wifi"),
        // Maison
        ServicePreset(name: L10n.t("preset_electricity"), category: .home, colorIndex: 2, symbol: "bolt.fill"),
        ServicePreset(name: L10n.t("preset_water"), category: .home, colorIndex: 5, symbol: "drop.fill"),
        // Assurances
        ServicePreset(name: L10n.t("preset_home_insurance"), category: .insurance, colorIndex: 10, symbol: "house.fill"),
        ServicePreset(name: L10n.t("preset_car_insurance"), category: .insurance, colorIndex: 6, symbol: "car.fill"),
        ServicePreset(name: L10n.t("preset_health_insurance"), category: .insurance, colorIndex: 4, symbol: "cross.case.fill"),
        // Transport
        ServicePreset(name: L10n.t("preset_transit"), category: .transport, colorIndex: 1, symbol: "tram.fill")
    ]
}
