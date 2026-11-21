# 💳 Subs — le guide complet (version 1.1)

> **Nouveau en 1.1 : les échéances.** Passeport, carte d'identité, contrôle technique, garanties, cartes cadeaux, ordonnances, entretien de la chaudière… Tout ce qui expire un jour, avec plusieurs rappels possibles (6 mois, 3 mois, 1 mois, la veille…). Nouvel onglet **Échéances**, et elles apparaissent aussi dans le **Calendrier** (petit losange) et sur l'accueil quand elles approchent.

Ce dossier contient **tout** : le projet Xcode prêt à ouvrir, l'icône, l'achat intégré (même code que Swipe Photos), les textes App Store en 5 langues, un studio de captures d'écran et la politique de confidentialité.
Lis ce guide dans l'ordre. Chaque étape est expliquée clic par clic.

---

## Sommaire

1. [Ce que fait l'app (et pourquoi elle va marcher)](#1-ce-que-fait-lapp-et-pourquoi-elle-va-marcher)
2. [La charte de ton profil App Store](#2-la-charte-de-ton-profil-app-store)
3. [Contenu du dossier](#3-contenu-du-dossier)
4. [Installer l'app sur ton iPhone](#4-installer-lapp-sur-ton-iphone)
5. [Tester l'achat et les rappels sans payer](#5-tester-lachat-et-les-rappels-sans-payer)
6. [Publier sur l'App Store](#6-publier-sur-lapp-store)
7. [Dépannage](#7-dépannage)

---

## 1. Ce que fait l'app (et pourquoi elle va marcher)

**Le besoin** : tout le monde paie des abonnements (streaming, musique, sport, box, forfait, assurances, IA, cloud…). La plupart des gens ne savent pas combien ça fait au total, oublient la date des prélèvements et se font piéger par des essais gratuits qui deviennent payants.

**Pourquoi Subs** : les apps concurrentes vendent… un abonnement pour suivre tes abonnements. Subs est une **app d'abonnements sans abonnement** : achat unique, pas de pub, pas de compte, pas d'accès à la banque. C'est exactement l'image de ton profil.

### Les fonctions
| Écran | Ce qu'on y trouve |
|---|---|
| **Abonnements** | Le **vrai total** (par mois ou par an, touche Mois/An), le coût par jour, les **essais gratuits qui se terminent** (carte orange), les **prochains prélèvements** des 30 jours, la liste triable (prochain, prix, nom), les abonnements **résiliés** et l'argent **économisé** |
| **+** (en bas à droite) | **41 services et factures pré-remplis** (Netflix, Spotify, iCloud+, salle de sport, forfait mobile, électricité, assurances…) ou un abonnement personnalisé. **Aucun prix inventé** : l'utilisateur saisit son vrai prix |
| **Fiche d'un abonnement** | Prix, part réelle si partagé, prochain prélèvement, coût par mois / an / 5 ans, les 6 prochains prélèvements, bouton **Gérer / résilier** (App Store ou site du service), bouton **J'ai résilié** (confettis + économies) |
| **Échéances** *(1.1)* | Papiers, véhicule, maison, santé, garanties, cartes & bons d'achat, contrats, animaux : **26 modèles** + personnalisé. Pour chacune : date d'expiration, **plusieurs rappels** (jour J → 90 jours avant), renouvellement régulier facultatif (tous les ans, 2 ans…), notes. Boutons **C'est renouvelé** (nouvelle date, les rappels repartent) et **Plus besoin de suivre**. Couleur d'état : rouge (expiré / < 7 j), orange (< 30 j), vert. **Aucune durée de validité inventée** : elles changent selon les pays |
| **Calendrier** | Le mois avec un point de couleur sur chaque jour de prélèvement (et un losange pour les échéances), total du mois, détail du jour |
| **Stats** | Où part l'argent (graphique par catégorie), les 12 prochains mois, les 5 plus chers, les économies grâce aux résiliations |
| **⚙︎ Réglages** | Version illimitée, **heure des rappels**, rappel par défaut, **devise** (20 devises), 8 couleurs + transparence du verre, thème, vibrations, **export CSV**, tutoriel, noter l'app |
| **💡** | Idées & bugs (même écran que Swipe Photos), envoi par Mail |

### Les rappels
- Notification **le jour même, la veille, 2 / 3 jours ou 1 semaine avant** chaque prélèvement, à l'heure choisie (9 h par défaut).
- Pour un **essai gratuit** : « Fin de l'essai Disney+ — Premier prélèvement demain : 9,99 €. Résilie maintenant si tu ne veux pas payer. »
- L'autorisation des notifications est demandée **au moment où elle a du sens** : quand on enregistre son premier abonnement.
- Tout est programmé **sur l'iPhone** (pas de serveur). iOS limite à 64 rappels en attente : l'app garde les 60 plus proches et reprogramme la suite à chaque ouverture.

### Le modèle économique (le même que Swipe Photos)
- **5 abonnements actifs gratuits**, sans limite de temps. Rappels, calendrier, stats, essais gratuits : **tout est gratuit**.
- Au 6ᵉ, l'écran de paiement s'ouvre : **achat unique à vie (4,99 €)**, Restaurer mes achats, partage familial.
- Les abonnements résiliés ne comptent pas dans la limite (l'historique des économies reste gratuit).
- **3 échéances suivies gratuites** ; le **même achat unique** les rend illimitées (rien à créer de plus dans App Store Connect).

### Ce qui n'est pas inclus (et pourquoi)
- **Widget** et **synchronisation iCloud entre appareils** : ils nécessitent des fonctions (App Groups, CloudKit) qui **ne fonctionnent pas avec un Apple ID gratuit**. Ce seront de très bonnes mises à jour 1.1 une fois ton compte développeur payant actif. Les données sont déjà incluses dans la sauvegarde iCloud de l'iPhone.
- **Connexion bancaire** : volontairement absente. C'est un argument de vente (« pas d'accès à ta banque »).

---

## 2. La charte de ton profil App Store

Pour que les gens comprennent tout de suite qui tu es en voyant **Swipe Photos** et **Subs** côte à côte, toutes tes apps suivent les mêmes règles :

> **Que du vrai. Paiement unique. Pas de blabla.**

| Règle | Swipe Photos | Subs |
|---|---|---|
| **Paiement unique**, jamais d'abonnement | 4,99 € à vie | 4,99 € à vie |
| **Version gratuite vraiment utilisable** | 100 swipes | 5 abonnements, tout le reste gratuit |
| **Pas de pub, pas de pisteur, pas de compte** | ✓ | ✓ |
| **Rien ne quitte l'iPhone** | ✓ | ✓ (pas de banque non plus) |
| **Honnête** : pas de fausse promo, pas de compte à rebours, pas de chiffres inventés | ✓ | ✓ (aucun prix pré-rempli) |
| **Même design** : fond sombre, Liquid Glass, 8 couleurs, même écran de paiement, même 💡 | couleur Néon | couleur **Émeraude** |
| **Même icône** : deux cartes inclinées sur fond sombre, une couleur par app | rose | vert |
| **5 langues** : FR, EN, ES, DE, IT | ✓ | ✓ |

**Le bloc à mettre à la fin de chaque description App Store** (déjà dans la fiche de Subs, ajoute-le à Swipe Photos à la prochaine mise à jour) :
```
Achat unique. Pas d'abonnement. Pas de pub. Rien ne quitte ton iPhone.
```
Dans l'app, cette phrase apparaît en bas des Réglages.

> 💡 Dans App Store Connect, tu peux aussi remplir l'**URL marketing** et ton **nom de développeur** de la même manière pour toutes les apps : le profil paraîtra cohérent.

---

## 3. Contenu du dossier

```
Subs/
├── README.md                       ← ce guide
├── Subs.xcodeproj                  ← DOUBLE-CLIQUE ICI pour ouvrir le projet
├── Info.plist                      ← infos de l'app (déjà rempli)
├── Subs.storekit                   ← achat de test (pour essayer sans payer)
├── Subs/                           ← le code de l'app
│   ├── AppConfig.swift             ← ⚠️ À PERSONNALISER avant publication (e-mail, liens…)
│   ├── SubsApp.swift               ← point de départ
│   ├── ContentView.swift           ← tutoriel → 4 onglets
│   ├── HomeView.swift              ← onglet Abonnements (total, à venir, liste)
│   ├── CalendarScreen.swift        ← onglet Calendrier
│   ├── StatsScreen.swift           ← onglet Stats (graphiques)
│   ├── AddSubscriptionView.swift   ← choix d'un service
│   ├── SubscriptionEditor.swift    ← formulaire ajout / modification
│   ├── SubscriptionDetailView.swift← fiche d'un abonnement, résiliation
│   ├── Deadlines.swift             ← (1.1) les échéances : types, rappels, 26 modèles
│   ├── DeadlinesScreen.swift       ← (1.1) onglet Échéances, ajout, fiche, formulaire
│   ├── SettingsView.swift          ← réglages
│   ├── PaywallView.swift           ← écran de paiement (comme Swipe Photos)
│   ├── PurchaseManager.swift       ← achat intégré (StoreKit 2, même code que Swipe Photos)
│   ├── FeedbackView.swift          ← Idées & bugs (même code que Swipe Photos)
│   ├── OnboardingView.swift        ← tutoriel
│   ├── SubscriptionStore.swift     ← la logique (sauvegarde, totaux, calendrier)
│   ├── NotificationService.swift   ← les rappels
│   ├── Models.swift                ← abonnement, fréquences, catégories, couleurs
│   ├── Catalog.swift               ← les 41 services proposés
│   ├── Components.swift            ← icônes, lignes, boutons, vibrations
│   ├── Effects.swift               ← couleurs, Liquid Glass, fonds, confettis (comme Swipe Photos)
│   ├── Localization.swift          ← langue, devise, dates
│   ├── Strings.swift               ← tous les textes dans les 5 langues
│   ├── Assets.xcassets             ← icône + couleur
│   └── fr/en/es/de/it.lproj        ← nom de l'app sous l'icône
└── AppStore/
    ├── Fiche-App-Store.md          ← nom, description, mots-clés (5 langues), achat intégré, notes pour Apple
    ├── studio-captures.html        ← crée tes captures App Store (s'ouvre dans Safari)
    └── politique-de-confidentialite.html ← à mettre en ligne (obligatoire)
```

---

## 4. Installer l'app sur ton iPhone

1. **Décompresse** `Subs.zip` et mets le dossier **Subs** dans **Documents** (à côté de SwipePhotos).
2. **Double-clique** sur `Subs.xcodeproj`.
3. Colonne de gauche → icône bleue **Subs** → sous **TARGETS** : **Subs** → onglet **Signing & Capabilities** → **Team** : *Enzo Bataille (Personal Team)*.
   - Erreur sur le Bundle Identifier ? Mets `com.enzobataille.subs2026`.
4. Branche l'iPhone, choisis **ton iPhone** en haut (pas un simulateur), clique sur **▶︎**.

> L'app commence par le **tutoriel** (4 pages), puis l'écran d'accueil vide avec le bouton **Ajouter mon premier abonnement**.
> Aucune autorisation n'est demandée au lancement : les notifications sont demandées à l'enregistrement du premier abonnement.

---

## 5. Tester l'achat et les rappels sans payer

Comme pour Swipe Photos, le projet est en **mode démo** : lancé avec ▶︎ depuis Xcode, l'achat utilise `Subs.storekit` (produit à **4,99 €**) avec la **vraie fenêtre de paiement Apple** (mention « Environment: Xcode »), sans aucun paiement réel.

### Remplir l'app en 2 secondes
⚙︎ **Réglages** → tout en bas, **🧪 Mode test** → **Ajouter 8 abonnements + 5 échéances d'exemple** (dont un essai gratuit qui finit dans 4 jours, un abonnement partagé à 3, un abonnement résilié, un contrôle technique dans 12 jours et une carte cadeau expirée). Parfait pour tester et faire les captures. **Tout effacer** pour repartir de zéro.

### Tester le paiement
1. Avec les exemples, tu as déjà 7 abonnements actifs (plus que les 5 gratuits) : touche **+** → l'écran de paiement s'ouvre.
2. Touche **Débloquer pour 4,99 €** → fenêtre Apple → confirme : c'est débloqué.
3. Pour recommencer : 🧪 Mode test → **Revenir à la version gratuite**, et dans Xcode **Debug → StoreKit → Manage Transactions** → supprime l'achat.

### Tester une notification
🧪 Mode test → **Notification de test dans 5 secondes**, puis reviens tout de suite à l'écran d'accueil de l'iPhone : la notification arrive (avec le vrai texte d'un rappel).

> La section 🧪 Mode test n'apparaît **que** quand l'app est lancée depuis Xcode : elle n'existe pas dans la version App Store.

### Si le prix ne s'affiche pas (« Prix indisponible · Réessayer »)
Même chose que Swipe Photos : lance l'app **avec ▶︎ depuis Xcode**. Sinon : **Product → Scheme → Edit Scheme… → Run → Options → StoreKit Configuration** → **Subs.storekit**. Un bouton 🧪 de secours apparaît aussi sur l'écran de paiement.

---

## 6. Publier sur l'App Store

Le compte développeur payant (99 €/an) sert pour **toutes** tes apps : une seule inscription.

### 6.1 Personnaliser `AppConfig.swift`
- `privacyPolicyURL` : l'adresse de ta politique de confidentialité en ligne (voir 6.2).
- `supportEmail` : ton adresse de contact (tu peux réutiliser celle de Swipe Photos).
- `feedbackEmail` : ⚠️ **ton adresse e-mail** qui recevra les idées et bugs (remplace `ton.email@exemple.com`).
- `proProductID` : déjà rempli (`com.enzobataille.subs.unlimited`). Garde-le tel quel et utilise exactement le même dans App Store Connect.
- `appStoreID` : à remplir **après** la création de l'app (« Identifiant Apple », 10 chiffres). Pas obligatoire pour la 1ʳᵉ version.

### 6.2 Politique de confidentialité (obligatoire)
1. Ouvre `AppStore/politique-de-confidentialite.html` avec **TextEdit**, remplace `[TON E-MAIL DE CONTACT]` (6 fois ; la date est déjà remplie).
2. Mets-la en ligne comme pour Swipe Photos (page **Notion** publique ou **Google Doc** partagé), copie l'adresse dans `AppConfig.swift` et dans App Store Connect.

### 6.3 Créer l'app et l'achat intégré
1. <https://appstoreconnect.apple.com> → **Apps** → **+** → **Nouvelle app** : iOS, nom `Subs – Suivi d'abonnements`, langue Français, Bundle ID `com.enzobataille.subs`, SKU `subs001`.
2. **Prix et disponibilité** → **Gratuit**.
3. **Achats intégrés** → **+** → **Non consommable** → identifiant `com.enzobataille.subs.unlimited` → prix **4,99 €** (détails dans `AppStore/Fiche-App-Store.md`).
4. Le **Paid Apps Agreement**, le RIB, les infos fiscales et le **Small Business Program** (15 % de commission) sont déjà valables si tu les as faits pour Swipe Photos.

### 6.4 Remplir la fiche
- Textes en **5 langues** : copie-colle depuis `AppStore/Fiche-App-Store.md`. ⚠️ Aucun nom de marque dans le nom, le sous-titre ou les mots-clés.
- **Catégorie** : **Finance**.
- **Captures** : 🧪 → exemples, captures sur l'iPhone, puis `AppStore/studio-captures.html` dans Safari. iPhone 6,9" **et** iPad 13" (simulateur iPad dans Xcode → ⌘ S).
- **Confidentialité** : « Aucune donnée collectée ». **Âge** : 4+.
- **Notes pour Apple** : copie le bloc de la fiche.

### 6.5 Envoyer l'app
1. **Signing & Capabilities** → **Team** : ton **compte payant**.
2. En haut d'Xcode : **Any iOS Device (arm64)**.
3. **Product → Archive** → **Distribute App** → **App Store Connect** → **Distribute**.
4. Dans App Store Connect : version 1.0 → **Build** → **+**. Ajoute aussi l'**achat intégré** à la version.
5. **Ajouter pour vérification** → **Soumettre**.

### 6.6 Si Apple refuse
Refus possibles et réponses :
- **2.3.7 / 5.2.1 (marques)** : tu as mis un nom de marque dans le nom, le sous-titre ou les mots-clés → enlève-le.
- **4.2 (fonctionnalité minimale)** : rare pour ce type d'app ; réponds en listant rappels, essais gratuits, calendrier, statistiques, export, 5 langues.
- **3.1.1 (achat)** : vérifie que l'achat intégré est ajouté à la version.

---

## 7. Dépannage

| Problème | Solution |
|---|---|
| Erreur rouge à la compilation | Clique sur l'erreur, copie le texte (ou fais une photo) et envoie-le à Claude |
| `Signing … requires a development team` | Partie 4, étape 3 |
| `Failed Registering Bundle Identifier` | Change le Bundle Identifier (ajoute des chiffres) |
| Pas de notification | Réglages iPhone → Subs → Notifications → Autoriser. Vérifie aussi que le rappel de l'abonnement n'est pas sur « Aucun rappel » |
| La notification n'arrive pas pendant que l'app est ouverte | Elle s'affiche quand même en bannière ; sinon ferme l'app pour tester |
| Mauvaise devise | ⚙︎ → Devise (ça change l'affichage, pas les montants) |
| « Prix indisponible · Réessayer » | Lance avec ▶︎ depuis Xcode (partie 5) |
| L'app ne s'ouvre plus après 7 jours | Compte gratuit : rebranche l'iPhone et clique sur ▶︎. **Tes abonnements sont conservés.** |

---

## 8. Mettre à jour l'app déjà publiée (version 1.1)

1. Le numéro de version est déjà passé à **1.1** (build 2) dans le projet.
2. App Store Connect → ton app → **+ Version ou plateforme** → iOS → `1.1`.
3. **Nouveautés de cette version** : copie-colle les textes de `AppStore/Fiche-App-Store.md` (section « Nouveautés de la version 1.1 »), et remplace la description par la nouvelle (ligne **NOUVEAU – ÉCHÉANCES** ajoutée).
4. Xcode : **Product → Archive** → **Distribute App**, choisis le build dans la version 1.1, **Soumettre**.
5. Les données des utilisateurs sont conservées : les échéances sont enregistrées dans un fichier à part (`deadlines.json`).
