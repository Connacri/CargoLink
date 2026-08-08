# 📦 CargoLink

> Plateforme mobile type **DHL** qui connecte les **micro-importateurs** (excédent de bagage) aux **clients** en Algérie pour importer des produits à moindre coût.

| | | |
|---|---|---|
| 🎯 **–50 à –70 %** vs DHL/FedEx | 🇩🇿 Optimisé marché algérien | 🏗 Flutter + Supabase |

https://connacri.github.io/CargoLink/
---

## ✨ Vision

Connecter des **micro-imports** (voyageurs avec excédent de bagage) et des **clients** qui veulent importer des produits. Le micro-importateur rentabilise sa franchise bagage, le client paie une fraction du prix des transporteurs classiques.

### Pour les clients
- 🔍 Rechercher & filtrer des shipments (destination, prix, date)
- 📦 Réserver du poids avec détails produit + photos
- 🛰 Suivi GPS en temps réel (Supabase Realtime)
- 💳 Paiement sécurisé (intégration passerelle prévue)
- 📜 Historique de commandes + signalement de litige/fraude

### Pour les micro-imports
- 🪪 Enregistrement KYC (passeport + live photo) & vérification admin
- 🚢 Publier des shipments (poids, prix, destination, vols)
- 📥 Gérer les commandes reçues (accepter/refuser)
- 🛰 Mettre à jour le suivi GPS
- 💰 Suivre ses revenus

### Pour l'admin
- 🔎 Vérifier / approuver / rejeter les micro-imports
- ⚖️ Gérer les litiges et la fraude
- 📈 Analytics & revenus
- 🛡 Modération

---

## 🏗 Stack Technique

**Frontend** — Flutter 3.44 (Dart 3.12) · Riverpod (state) · Material 3
**Backend** — Supabase (PostgreSQL) · Realtime · Auth (Email/Google/Apple) · Storage (profiles, documents, bookings)
**Externes** — Google Maps · Firebase Messaging · url_launcher · image_picker

---

## 📁 Structure du Projet

```
cargolink/
├── lib/
│   ├── main.dart                    # Point d'entrée + routing + app shell
│   ├── models.dart                  # User, Shipper, Shipment, Booking, Tracking, Dispute, Notification, Payment
│   ├── providers.dart               # Providers Riverpod (auth, shipments, bookings, tracking, disputes, ...)
│   ├── auth_service.dart           # Inscription, login, Google, reset pwd
│   ├── shipper_shipment_service.dart# Micro-imports + shipments
│   ├── booking_payment_service.dart # Réservations + paiements
│   ├── tracking_dispute_service.dart# Suivi GPS, litiges, notifications
│   ├── storage_service.dart        # Upload Supabase Storage
│   ├── supabase_config.dart        # Config Supabase + thème + enums
│   ├── client_home_screen.dart     # Écran client (recherche + filtres)
│   └── booking_screen.dart         # Écran de réservation (photos + poids)
├── database_setup.sql               # Schéma SQL complet (tables + RLS + triggers)
├── android/ · ios/ · web/ · windows/ # Targets multi-plateformes
└── ...
```

> Une cible Windows et web sont activées (`windows/` et `web/` présentes).

---

## 🗄 Base de données (Supabase)

Script prêt : **`database_setup.sql`** — crée le schéma, les politiques RLS et les triggers.

**Tables :**
`users` · `shippers` · `shipments` · `bookings` · `shipment_tracking` · `disputes` · `notifications` · `payments` · `shipper_flags`

**Sécurité :**
- ✅ RLS activé sur toutes les tables
- ✅ Policies par rôle (client / micro-import' / admin)
- ✅ Triggers `SECURITY DEFINER` (réservation de poids) protégés
- ✅ Policies RLS testées (voir Traces de tests) : création de réservation, confirmation shipper, tracking, litiges client/admin, refus de falsification

### Storage Buckets
`profiles` · `documents` · `bookings` — publics par défaut.

---

## 🔐 Setup complet

### 1. Supabase
1. Créez un projet sur [supabase.com](https://supabase.com).
2. Dans **SQL Editor**, exécutez le contenu de `database_setup.sql`.
3. **Authentication → Providers** : activez Email/Password (fait par défaut) + Google/Apple si souhaité.
4. **Storage → Buckets** : créez `profiles`, `documents`, `bookings`.

### 2. Clé API
La clé n'est volontairement **pas committée** (secret). Pour la fournir à l'app :

```bash
# Windows (PowerShell)
flutter run --dart-define=SUPABASE_ANON_KEY=VOTRE_CLE_ANON
# Build APK
flutter build apk --release --dart-define=SUPABASE_ANON_KEY=VOTRE_CLE_ANON
```

L'URI du projet est préconfigurée dans `lib/supabase_config.dart`.

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

// Créer une réservation
final booking = await bookingService.createBooking(shipmentId: s.id, clientId: uid, productName: 'iPhone 15',
    productDescription: 'Neuf scellé', productPhotosUrl: urls, requestedWeightKg: 0.8);

// Suivi temps réel
trackingService.listenToTrackingUpdates(bookingId).listen((updates) { /* mise à jour UI */ });

// Litige
await disputeService.createDispute(bookingId: b.id, reportedByUserId: uid, type: 'customs_seizure', description: '...');
```

---

## 🧪 Tests & Qualité

```bash
flutter test      # tests unitaires des modèles
flutter analyze   # 0 erreur, 0 avertissement (56 infos de style)
```

Tests unitaires couverts : `User.fromJson`, `Shipment.isActive`, `remainingWeightKg`.

Tests RLS exécutés en base (traces réelles) : création de booking client ✅ · trigger poids réservé ✅ · shipper voit/confirme booking ✅ · shipper insert tracking ✅ · admin gère litiges ✅ · client crée litige ✅ · client ne peut PAS altérer un shipment d'un tiers ✅ · falsification de booking refusée ✅.

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

> **Statut build** : le build Android, Windows et Web compile et est automatisé via GitHub Actions (voir plus bas). La génération de l'APK se fait en CI (`flutter build apk --release --dart-define=SUPABASE_ANON_KEY=...`).

---

## 🤖 CI / GitHub Actions (release versionnée)

Un workflow est prévu pour automatiser les releases : build **APK signé**, **installateur Windows (Inno Setup)**, **site web**, génération d'un **README** avec badges, version bump + **tag** + **GitHub Release**.

Workflow : `.github/workflows/release.yml`

### Secrets GitHub à configurer (Settings → Actions → Secrets → New repository secret)

| Secret | Contenu | Usage |
|---|---|---|
| `KEYSTORE_BASE64` | Keystore `cargolink-release.jks` encodé en **base64** | Signature APK |
| `KEYSTORE_PASSWORD` | Mot de passe du keystore | Signature APK |
| `KEYSTORE_KEY_ALIAS` | Alias de la clé | Signature APK |
| `KEY_PASSWORD` | Mot de passe de la clé | Signature APK |
| `SUPABASE_ANON_KEY` | Clé **anon** Supabase (public API key) | Compilée dans l'APK/web/Windows |

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

> ⚠️ Ne committejamais le fichier `.jks` ni les mots de passe.

---

## 🗺 Roadmap

| Phase | Statut |
|---|---|
| MVP mobile (client/micro'/admin) | en cours |
| Paiement (Stripe / Chardly) | à intégrer |
| Notifications push (FCM) | à configurer |
| Web dashboard + CI/CD releases | à finaliser |
| Multi-langues (FR/EN/AR) | Phase 3 |

---

## 📄 License

MIT © 2026 — CargoLink
