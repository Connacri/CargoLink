# 📦 CargoLink

> Plateforme mobile type **DHL** qui connecte les **micro-importateurs** (voyageurs avec excédent de bagage) aux **clients** en Algérie pour importer des produits à moindre coût.

| | | |
|---|---|---|
| 🎯 **–50 à –70 %** vs DHL/FedEx | 🇩🇿 Optimisé marché algérien | 🏗 Flutter + Supabase Realtime |

🔗 **Démo web (GitHub Pages)** : https://connacri.github.io/CargoLink/

---

## ✨ Vision

Connecter des **micro-importateurs** (voyageurs disposant d'une franchise bagage) et des **clients** qui veulent importer des produits. Le micro-importateur rentabilise son excédent de bagage, le client paie une fraction du prix des transporteurs classiques.

---

## 🚀 Fonctionnalités

### 🧑 Pour les clients
- 🔍 **Recherche & filtres** : destinations, origine, prix, tri (smart filters).
- 📦 **Assistant de réservation** en 4 étapes : *Produit → Photos → Paiement → Terminé*.
- 🎫 **Confirmation avec QR code** : ticket récapitulatif (référence, produit, poids) + bouton *« Enregistrer la confirmation »* (sauvegarde en galerie).
- 💳 **Paiement** : Espèces, Virement bancaire, CCP/CIB, **Chargily** (EDAHABIA / carte), **Stripe** (international).
- 🗂 **Mes commandes** : filtres par statut, annulation, icônes de statut (« Expéditeur a confirmé », « Paiement reçu / en attente »), profil expéditeur cliquable, mise à jour en temps réel.
- 🛰 **Suivi de colis** : timeline DHL/UPS-style, barre de progression, preuve de livraison photo, confirmation de réception, notation de l'expéditeur.
- 💬 **Chat** avec l'expéditeur (statuts envoyé / délivré / lu, push FCM).
- 🔔 **Notifications** : annonces ciblées + notifications personnelles, badge non-lu, « tout marquer comme lu ».
- ⚖️ **Litiges** : signalement de litige / fraude (saisie douane, colis non livré, etc.).
- ✍️ **Feedback** : signaler un bug en dessinant sur l'écran (BetterFeedback).

### 🧳 Pour les micro-importateurs
- 🪪 **KYC complet** : passeport + **live selfie** (détection de visage ML Kit), dossier modifiable et re-vérifiable.
- 🚢 **Publier des shipments** : poids, prix, destination, numéro de vol, photos.
- 📥 **Gérer les commandes reçues** : confirmer / refuser, poids alloué, carte client.
- 🛰 **Mettre à jour le suivi** (événements + points GPS).
- 💰 **Revenus & statistiques** : tableau de bord, graphique CA, commissions, historique.
- ⭐ **Profil public** : note, avis, badge vérifié.

### 🛡 Pour l'admin
- 🔎 **Centre de vérification** KYC (approuver / rejeter / re-vérifier).
- ⚖️ **Litiges & fraudes**, flags expéditeur.
- 💸 **Transactions & commissions**, allocations de paiement, payouts.
- 📣 **Broadcasts** ciblés par rôle.
- ✍️ **Feedback inbox** (retours utilisateurs).
- ⚙️ **Paramètres plateforme** (commission, payouts, devise).
- 📈 **Analytics fondateur** (super admin).

---

## 🔄 Workflows

### 1. Cycle de vie d'un envoi (client → expéditeur)

```mermaid
sequenceDiagram
    autonumber
    actor C as Client
    actor S as Micro-importateur
    participant P as Plateforme (Supabase)

    C->>P: Recherche & filtre les offres actives
    P-->>C: Liste des shipments (realtime, mise à jour en place)
    C->>P: Réservation (produit + photos + poids + méthode de paiement)
    P-->>C: Booking créé + ticket QR + référence
    Note over P,S: Notification push + realtime → dashboard expéditeur
    S->>P: Confirme / refuse la commande
    P-->>C: Statut mis à jour en direct (icône « Expéditeur a confirmé »)
    C->>P: Paiement (espèces / virement / CCP / Chargily / Stripe)
    P-->>C: « Paiement reçu » en direct
    S->>P: Départ, événements de suivi (vol, transit, douane…)
    C->>P: Consultation du suivi (timeline animée)
    S->>P: Photo de preuve de livraison
    C->>P: Confirme la réception + note l'expéditeur
```

### 2. Workflow de paiement

```mermaid
flowchart LR
    A[Réservation créée] --> B{Méthode de paiement}
    B -->|Espèces| C[Paiement à la livraison]
    B -->|Virement / CCP / CIB| D[Réf. bancaire affichée]
    B -->|Chargily| E[EDAHABIA / carte via passerelle]
    B -->|Stripe| F[Stripe international]
    C --> G[Booking marqué payé]
    D --> G
    E --> G
    F --> G
    G --> H[Statut « Paiement reçu » en temps réel]
```

### 3. Workflow de litige

```mermaid
flowchart TD
    A[Client signale un litige / fraude] --> B{Catégorie}
    B --> C[Saisie douane]
    B --> D[Colis non livré]
    B --> E[Autre / fraude]
    C --> F[Suivi + preuves photos]
    D --> F
    E --> F
    F --> G[Admin examine]
    G --> H[Résolution / remboursement / flag expéditeur]
```

### 4. Workflow chat

```mermaid
sequenceDiagram
    autonumber
    actor C as Client
    actor S as Expéditeur
    participant R as Realtime + FCM

    C->>R: Envoie un message
    R-->>C: Statut « envoyé »
    R-->>S: Realtime (écran ouvert) / push FCM (hors app)
    S->>R: Lit le message
    R-->>C: Statut « lu »
```

---

## 🎨 Animations & UI

- **Entrée en cascade** (`StaggeredEntrance`) : glissement + fondu des cartes de listes, décalage progressif par item.
- **Squelettes shimmer** : chargements de listes fluides (au lieu d'un simple spinner).
- **Icônes animées** (`AnimatedIconDot`) : pastilles pulsantes de statut.
- **Glass cards** + **entêtes en dégradé** (`GradientSliverHeader`) : effet « glassmorphism » moderne.
- **Fade-in au scroll** : apparition douce des sections pendant le défilement.
- **Timeline de suivi animée** : progression par étapes (DHL/UPS/FedEx style).
- **Réponse haptique** et transitions Material 3 natives.
- Feedback utilisateur avec **annotation au doigt** (mode dessin).

---

## 🌍 Multilangage

> **État actuel** : l'interface est **entièrement en français** (`Locale('fr')`), avec prise en charge des devise/locale via `intl`.

| Langue | Statut |
|---|---|
| 🇫🇷 Français (UI par défaut) | ✅ Actif |
| 🇬🇧 English | 🔜 Prévu (Phase 3) |
| 🇩🇿 العربية | 🔜 Prévu (Phase 3) |

Le passage au multilangage s'appuiera sur `flutter_localizations` + `gen-l10n` (fichiers `ARB`) sans changement de l'architecture (les chaînes sont déjà centralisées dans les écrans/thème).

---

## 🏗 Stack Technique

**Frontend** — Flutter 3.44 (Dart 3.12) · Riverpod 2.4 (state) · Material 3 · Lottie · shimmer
**Backend** — Supabase (PostgreSQL + Realtime + RLS) · Auth (Email/Google/Apple + pont Firebase) · Storage
**Paiement** — Chargily · Stripe
**Notifications** — Firebase Cloud Messaging + Supabase Realtime (statuts de message)
**Autres** — Google Maps / geolocator · ML Kit (live selfie) · QR (`qr_flutter`) · Galerie (`gal`) · BetterFeedback

---

## 📁 Structure du Projet

```
cargolink/
├── lib/
│   ├── main.dart                          # Point d'entrée (Firebase + FCM + BetterFeedback)
│   ├── app/                               # Shell applicatif, onglets par rôle, widgets globaux
│   ├── core/
│   │   ├── config/                        # supabase_config, firebase_options
│   │   ├── constants/ · enums/ · theme/   # AppTheme, enums (statuts, devises…)
│   │   ├── utils/                         # error_dialog…
│   │   └── widgets/                       # animations, shimmer, glass_card, ui_kit,
│   │                                      #   paginated_list, notification_widgets, chat_widgets…
│   ├── data/
│   │   ├── models/                        # User, Shipper, Shipment, Booking, Notification,
│   │   │                                  #   Chat, Payment, Dispute, Review, Broadcast…
│   │   └── services/                      # auth, shipper_shipment, booking_payment, tracking_dispute,
│   │                                      #   chat, broadcast, feedback, review, storage, realtime, fcm…
│   ├── providers/index.dart               # Tous les providers Riverpod (+ pagers + realtime)
│   ├── components/                        # tracking_timeline, shipper_card, revenue_bar_chart
│   └── screens/
│       ├── auth/                          # Login, signup, role selection, KYC gate, vérif email
│       ├── client/                        # Home, booking wizard, my orders, payment, tracking
│       ├── shipper/                       # Dashboard, registration/live selfie, bookings, stats
│       ├── chat/                          # Conversations + chat
│       ├── profile/                       # Profil utilisateur
│       └── admin/                         # Vérification, litiges, transactions, broadcasts, settings…
├── .github/workflows/                     # deploy.yml (web) + release.yml (APK/Windows versionné)
└── pubspec.yaml
```

---

## 🗄 Base de données (Supabase)

**Tables principales** : `users` · `shippers` · `shipments` · `bookings` · `shipment_tracking` · `shipment_events` · `shipment_proofs` · `payments` · `payment_allocations` · `payouts` · `platform_fees` · `disputes` · `claims` · `notifications` · `messages` · `conversations` · `reviews` · `broadcasts` · `feedback` · `shipper_flags` · `tracking_points` · `trips` · `device_tokens`

**Sécurité & Realtime**
- ✅ RLS activé sur toutes les tables, policies par rôle (client / micro-importateur / admin).
- ✅ Triggers `SECURITY DEFINER` protégés (réservation de poids, allocations).
- ✅ Publication **realtime** activée sur les tables métier (`supabase_realtime`) — listes mises à jour **en place** (patch des tiles) sans rechargement complet.
- ✅ Récupération automatique des canaux realtime (backoff exponentiel sur erreurs/expiration).

**Storage Buckets** : `profiles` · `documents` · `bookings` · `proofs`

---

## 🔐 Setup complet

### 1. Supabase
1. Créez un projet sur [supabase.com](https://supabase.com).
2. Dans **SQL Editor**, exécutez le script de schéma (tables + RLS + triggers).
3. **Authentication → Providers** : activez Email/Password + Google/Apple si souhaité.
4. **Storage → Buckets** : créez `profiles`, `documents`, `bookings`, `proofs`.
5. **Realtime → Tables** : activez `supabase_realtime` sur les tables métier.

### 2. Clé API
La clé n'est volontairement **pas committée** (secret). Pour la fournir à l'app :

```bash
# Windows (PowerShell)
flutter run --dart-define=SUPABASE_ANON_KEY=VOTRE_CLE_ANON
# Build APK
flutter build apk --release --dart-define=SUPABASE_ANON_KEY=VOTRE_CLE_ANON
```

L'URI du projet est préconfigurée dans `lib/core/config/supabase_config.dart`.

### 3. Flutter
```bash
flutter pub get
flutter analyze
flutter test
```

---

## 🔌 Exemples d'API

```dart
// Inscription
await authService.signUpWithEmail(email: e, password: p, fullName: n, phone: tel, role: 'client');

// Recherche de shipments actifs
final board = await shipmentService.getActiveShipments(destinationCity: 'Alger', originCountry: 'Turquie');

// Créer une réservation (assistant)
final booking = await bookingService.createBooking(shipmentId: s.id, clientId: uid, productName: 'iPhone 15',
    productDescription: 'Neuf scellé', productPhotosUrl: urls, requestedWeightKg: 0.8);

// Écouter les changements d'une table (mise à jour en place des listes)
ref.watch(tableChangesProvider(('bookings', 'client_id', uid)));

// Suivi temps réel
trackingService.listenToTrackingUpdates(bookingId).listen((updates) { /* mise à jour UI */ });

// Litige
await disputeService.createDispute(bookingId: b.id, reportedByUserId: uid, type: 'customs_seizure', description: '...');
```

---

## 🧪 Tests & Qualité

```bash
flutter analyze   # 0 erreur, 0 avertissement
flutter test      # tests unitaires des modèles
```

Tests unitaires couverts : modèles (`User.fromJson`, `Shipment.isActive`, `remainingWeightKg`, …).
Tests RLS exécutés en base : création de booking client ✅ · trigger poids réservé ✅ · shipper voit/confirme un booking ✅ · shipper insert tracking ✅ · admin gère les litiges ✅ · client crée un litige ✅ · client ne peut **pas** altérer le shipment d'un tiers ✅ · falsification de booking refusée ✅.

---

## 🛠 Commandes de Build locales

```bash
# Android (APK release)
flutter build apk --release
# Android AppBundle (Play Store)
flutter build appbundle --release
# Web
flutter build web --release
# Windows (desktop)
flutter build windows --release
```

> **Statut build** : Android, Windows et Web compilent et sont automatisés en CI (voir ci-dessous).

---

## 🤖 CI / GitHub Actions

### Deploy (Web → GitHub Pages)
`.github/workflows/deploy.yml` — déclenché sur chaque push vers `master` : build Flutter web avec la clé anon (secret) puis déploiement GitHub Pages.

### Release versionnée
`.github/workflows/release.yml` — build **APK signé** + **installateur Windows (Inno Setup)** + **site web**, version bump + **tag** + **GitHub Release**.

**Secrets GitHub à configurer** (Settings → Actions → Secrets → New repository secret) :

| Secret | Contenu | Usage |
|---|---|---|
| `KEYSTORE_BASE64` | Keystore `cargolink-release.jks` encodé en **base64** | Signature APK |
| `KEYSTORE_PASSWORD` | Mot de passe du keystore | Signature APK |
| `KEYSTORE_KEY_ALIAS` | Alias de la clé | Signature APK |
| `KEY_PASSWORD` | Mot de passe de la clé | Signature APK |
| `SUPABASE_ANON_KEY` | Clé **anon** Supabase | Compilée dans l'APK/web/Windows |

**Générer le keystore (une fois) :**
```bash
keytool -genkeypair -v -keystore cargolink-release.jks -alias cargolink \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass VOTRE_STORE_PASS -keypass VOTRE_KEY_PASS \
  -dname "CN=CargoLink, OU=Dev, O=CargoLink, L=Alger, S=Alger, C=DZ"
# Encodage base64 (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("cargolink-release.jks"))
# Collez le résultat dans le secret KEYSTORE_BASE64
```

> ⚠️ Ne committez jamais le fichier `.jks` ni les mots de passe.

---

## 🗺 Roadmap

| Phase | Statut |
|---|---|
| MVP mobile (client / micro-importateur / admin) | ✅ |
| Paiement (Chargily + Stripe) | ✅ intégré |
| Notifications push (FCM) + statuts de message | ✅ |
| QR de confirmation + sauvegarde galerie | ✅ |
| Mise à jour temps réel sans redémarrage (patch pagers) | ✅ |
| Web dashboard + CI/CD releases | ✅ automatisé |
| Multi-langues (FR/EN/AR) | 🔜 Phase 3 |

---

## 📄 License

MIT © 2026 — CargoLink