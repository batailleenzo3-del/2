//
//  AppConfig.swift
//  ⚠️ Les réglages à personnaliser avant de publier l'app (voir README, partie 6).
//

import Foundation

nonisolated enum AppConfig {

    // MARK: À remplir avant publication

    /// Adresse web de ta politique de confidentialité (ex : "https://www.notion.so/…").
    /// Laisse vide pour masquer le lien dans les Réglages.
    static let privacyPolicyURL = ""

    /// Ton adresse e-mail de contact (ex : "subs.app@gmail.com").
    /// Laisse vide pour masquer le bouton « Contacter ».
    static let supportEmail = ""

    /// Adresse qui reçoit les idées et signalements de bugs (bouton 💡).
    /// ⚠️ Remplace ce placeholder par ta vraie adresse.
    static let feedbackEmail = "ton.email@exemple.com"

    /// L'identifiant numérique de l'app sur l'App Store (visible dans App Store Connect,
    /// « Identifiant Apple », ex : "6740000000"). Sert au bouton « Noter l'app ».
    static let appStoreID = ""

    // MARK: Achat intégré (version illimitée)

    /// Identifiant de l'achat intégré (non consommable, à vie) à créer dans App Store Connect.
    /// Doit être identique dans App Store Connect et dans Subs.storekit.
    /// Le prix (4,99 €) se règle uniquement dans App Store Connect, jamais dans le code.
    static let proProductID = "com.enzobataille.subs.unlimited"

    /// Nombre d'abonnements actifs suivis gratuitement. Tout le reste (rappels, calendrier,
    /// statistiques, essais gratuits) est gratuit et sans limite.
    static let freeSubscriptionLimit = 5

    /// Nombre d'échéances (papiers, garanties…) suivies gratuitement.
    /// Le même achat unique les rend illimitées.
    static let freeDeadlineLimit = 3

    // MARK: Rappels

    /// Heure par défaut des notifications (modifiable dans les Réglages).
    static let defaultReminderHour = 9

    /// iOS n'accepte que 64 notifications programmées par app : on garde une marge.
    static let maxScheduledNotifications = 60
}
