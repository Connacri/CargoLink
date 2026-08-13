# 📦 CargoLink - Guide Complet d'Implémentation

## Table des matières
1. [Configuration Initiale](#configuration-initiale)
2. [Setup Supabase](#setup-supabase)
3. [Setup Flutter](#setup-flutter)
4. [Structure du Projet](#structure-du-projet)
5. [Fonctionnalités Principales](#fonctionnalités-principales)
6. [API & Services](#api--services)
7. [Déploiement](#déploiement)
8. [Améliorations Futures](#améliorations-futures)

---

## 🔧 Configuration Initiale

### Prérequis
- Flutter 3.x
- Dart 3.x
- Node.js 16+ (pour Supabase CLI)
- Android Studio / Xcode
- Git

### 1. Créer un compte Supabase
```bash
# Aller sur https://supabase.com
# Créer un nouveau projet
# Obtenir les credentials:
# - Project URL
# - Anon Key (Public)
# - Service Role Key (Secret)
```

### 2. Cloner et configurer le projet
```bash
# Cloner le repo
git clone https://github.com/Connacri/cargolink.git
cd cargolink

# Installer les dépendances Flutter
flutter pub get

# Générer les fichiers de code
flutter pub run build_runner build
```

---

## 🔐 Setup Supabase

### Étape 1: Créer la base de données

1. **Aller dans SQL Editor** dans Supabase Dashboard
2. **Copier et coller** le contenu de `database_setup.sql`
3. **Exécuter** le script
4. **Vérifier** que toutes les tables sont créées

```sql
-- Dans Supabase SQL Editor
-- Coller le contenu de database_setup.sql
-- Cliquer sur "Run"
```

### Étape 2: Configurer l'authentification

1. **Authentication → Providers**
2. Activer:
   - Email/Password
   - Google OAuth (optionnel)
   - Apple Sign-in (optionnel)

3. **Authentication → Email Templates**
   - Configurer les templates de confirmation email

### Étape 3: Configurer le Storage

1. **Storage → Buckets**
2. Créer les 3 buckets (si pas déjà créés):
   - `profiles` (public)
   - `documents` (public)
   - `bookings` (public)

3. **Politique d'accès**: Ajuster selon vos besoins

### Étape 4: Ajouter les credentials Flutter

Mettre à jour `supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';
  // ...
}
```

---

## 🎨 Setup Flutter

### Étape 1: Configuration de base

```bash
# Créer le projet
flutter create cargolink

# Ajouter les dépendances
flutter pub add supabase_flutter flutter_riverpod google_sign_in
flutter pub add camera image_picker geolocator google_maps_flutter
```

### Étape 2: Configuration Android

**android/app/build.gradle**:
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}

dependencies {
    implementation 'com.google.android.gms:play-services-maps:18.2.0'
    implementation 'com.google.android.gms:play-services-location:21.0.1'
}
```

**android/app/src/main/AndroidManifest.xml**:
```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    
    <application>
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
    </application>
</manifest>
```

### Étape 3: Configuration iOS

**ios/Runner/Info.plist**:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>CargoLink needs your location for tracking</string>
<key>NSCameraUsageDescription</key>
<string>CargoLink needs camera access for photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>CargoLink needs photo library access</string>
```

### Étape 4: Tester la connexion

```bash
flutter run --debug
```

---

## 📂 Structure du Projet

```
cargolink/
├── lib/
│   ├── main.dart                    # Point d'entrée
│   ├── config/
│   │   ├── supabase_config.dart    # Config Supabase
│   │   ├── app_theme.dart          # Thème global
│   │   └── constants.dart          # Constantes
│   ├── models/
│   │   └── models.dart             # Tous les modèles
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── shipper_shipment_service.dart
│   │   ├── booking_payment_service.dart
│   │   ├── tracking_dispute_service.dart
│   │   └── storage_service.dart
│   ├── providers/
│   │   └── providers.dart          # Riverpod providers
│   ├── screens/
│   │   ├── auth/
│   │   ├── client/
│   │   ├── shipper/
│   │   └── admin/
│   └── widgets/
│       └── custom_widgets.dart
├── assets/
├── pubspec.yaml
└── README.md
```

---

## 🚀 Fonctionnalités Principales

### Pour les Clients

| Fonctionnalité | Status | Description |
|---|---|---|
| Recherche shipments | ✅ | Filtrer par destination, prix, date |
| Réservation | ✅ | Réserver du poids avec détails produit |
| Suivi GPS | ✅ | Tracker en temps réel via Realtime Supabase |
| Paiement | ⏳ | Intégrer Stripe/Chardly |
| Historique | ✅ | Voir toutes les commandes |
| Disputes | ✅ | Signaler problèmes/fraude |

### Pour les Micro-importateurs

| Fonctionnalité | Status | Description |
|---|---|---|
| KYC | ✅ | Photo live + passeport |
| Publier shipment | ✅ | Définir poids, prix, destination |
| Gestion commandes | ✅ | Accepter/refuser bookings |
| Suivi envois | ✅ | Mettre à jour GPS |
| Revenus | ✅ | Voir earnings |

### Pour l'Admin

| Fonctionnalité | Status | Description |
|---|---|---|
| Vérifier shippers | ✅ | Approuver/rejeter |
| Gérer disputes | ✅ | Résoudre/rejeter |
| Analytics | ✅ | Statistiques |
| Modération | ✅ | Bloquer utilisateurs |

---

## 🔌 API & Services

### AuthService
```dart
// Sign up
await authService.signUpWithEmail(
  email: 'user@example.com',
  password: 'password',
  fullName: 'John Doe',
  phone: '+213700000000',
  role: 'client',
);

// Sign in
await authService.signInWithEmail(
  email: 'user@example.com',
  password: 'password',
);

// Get current user
final user = await authService.getCurrentUserProfile();
```

### ShipmentService
```dart
// Search active shipments
final shipments = await shipmentService.getActiveShipments(
  destinationCity: 'Alger',
  originCountry: 'Turquie',
);

// Publish new shipment
final shipment = await shipmentService.publishShipment(
  shipperId: 'shipper-id',
  originCountry: 'Chine',
  destinationCity: 'Alger',
  availableWeightKg: 50,
  pricePerKg: 1000,
  departureDate: DateTime.now(),
  arrivalDate: DateTime.now().add(Duration(days: 7)),
);
```

### BookingService
```dart
// Create booking
final booking = await bookingService.createBooking(
  shipmentId: 'shipment-id',
  clientId: 'client-id',
  productName: 'iPhone 14',
  productDescription: 'New, sealed',
  productPhotosUrl: ['photo1.jpg', 'photo2.jpg'],
  requestedWeightKg: 0.8,
);

// Get booking stats
final stats = await bookingService.getBookingStats('client-id');
```

### TrackingService (Real-time)
```dart
// Add tracking update
await trackingService.addTrackingUpdate(
  bookingId: 'booking-id',
  status: 'in_transit',
  latitude: 36.7536,
  longitude: 3.0588,
  notes: 'Left Istanbul warehouse',
);

// Listen to real-time updates
trackingService.listenToTrackingUpdates('booking-id')
  .listen((updates) {
    // Update UI with new tracking data
  });
```

### DisputeService
```dart
// Create dispute
final dispute = await disputeService.createDispute(
  bookingId: 'booking-id',
  reportedByUserId: 'user-id',
  type: 'customs_seizure',
  description: 'Package seized at customs',
  evidencePhotosUrl: ['photo1.jpg'],
);

// Resolve dispute (admin)
await disputeService.resolveInFavorOfClient(
  disputeId: 'dispute-id',
  resolution: 'Refund issued',
);
```

---

## 📱 Exemples d'Utilisation

### Exemple 1: Créer une réservation

```dart
// 1. Trouver un shipment
final shipments = await shipmentService.getActiveShipments(
  destinationCity: 'Alger',
);

// 2. Créer une réservation
final booking = await bookingService.createBooking(
  shipmentId: shipments[0].id,
  clientId: currentUserId,
  productName: 'Laptop',
  productDescription: 'MacBook Pro 16"',
  productPhotosUrl: ['url1', 'url2'],
  requestedWeightKg: 2.5,
);

// 3. Traiter le paiement
await paymentService.completePayment(
  paymentId: booking.id,
  transactionId: 'stripe_123',
);

// 4. Notifier le shipper
await notificationService.notifyShipperBookingConfirmed(
  shipperId: shipments[0].shipperId,
  bookingId: booking.id,
  productName: booking.productName,
  allocatedWeight: booking.allocatedWeightKg,
);
```

### Exemple 2: Suivre une commande

```dart
// Écouter les mises à jour en temps réel
trackingService.listenToTrackingUpdates(bookingId)
  .listen((tracking) {
    setState(() {
      currentLocation = LatLng(tracking.latitude, tracking.longitude);
      status = tracking.status;
    });
  });
```

---

## 🚀 Déploiement

### BuildApk Android
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Ou AAB pour Google Play
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Build iOS
```bash
flutter build ios --release
# Puis archiver dans Xcode et soumettre à l'App Store
```

### Configuration GitHub Actions (CI/CD)
```yaml
name: Build & Deploy

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
      - run: flutter build apk --release
      - run: flutter build appbundle --release
```

---

## 🔒 Sécurité

### À implémenter

1. **Rate Limiting**: Ajouter rate limiting sur les APIs
2. **Encryption**: Chiffrer les données sensibles
3. **Two-Factor Auth**: 2FA pour les comptes admin
4. **Fraud Detection**: ML pour détecter les fraudes
5. **Data Validation**: Valider tous les inputs

### Secrets Management
```dart
// Utiliser env_variables ou flutter_dotenv
// NE PAS committer les secrets!
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}
```

---

## 📊 Monitoring & Analytics

### Recommended Tools
- **Firebase Crashlytics**: Crash reporting
- **Firebase Analytics**: User analytics
- **Sentry**: Error tracking
- **Mixpanel**: User behavior

---

## 🎯 Améliorations Futures

### Phase 2
- [ ] Web Dashboard (Next.js)
- [ ] Push Notifications (FCM)
- [ ] Payment Gateway Integration (Stripe, Chardly)
- [ ] Advanced Analytics
- [ ] Machine Learning for matching
- [ ] Insurance Integration

### Phase 3
- [ ] Multi-language Support (EN, FR, AR)
- [ ] Offline Mode
- [ ] Voice Calls (Twilio)
- [ ] Video Calls (Agora)
- [ ] Wallet System

### Phase 4
- [ ] AI Chatbot Support
- [ ] Blockchain for verification
- [ ] Cryptocurrency payments
- [ ] NFT Certificates

---

## 📞 Support

### Documentation
- Flutter: https://flutter.dev/docs
- Supabase: https://supabase.com/docs
- Riverpod: https://riverpod.dev

### Contact
- Email: support@cargolink.com
- GitHub: https://github.com/Connacri/cargolink

---

## 📄 License

MIT License - Voir LICENSE.md

---

## 👨‍💻 Author

**Connacri** - Senior Flutter Engineer
- GitHub: @Connacri
- Email: contact@connacri.dev

---

**Version**: 1.0.0  
**Last Updated**: Août 2026
