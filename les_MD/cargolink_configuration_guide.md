# 🚀 CargoLink - Configuration Complète & Quick Start

---

## 📦 PUBSPEC.YAM
L

```yaml
name: cargolink
description: P2P Cargo Marketplace for Micro-importers in Algeria
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # ============ STATE MANAGEMENT ============
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.0.0
  riverpod_generator: ^2.0.0
  
  # ============ BACKEND & DATABASE ============
  supabase_flutter: ^1.10.0
  realtime_client: ^0.1.0
  gotrue: ^1.0.0
  postgrest: ^0.0.1
  
  # ============ AUTHENTICATION ============
  google_sign_in: ^6.1.0
  apple_sign_in: ^0.1.1
  flutter_appauth: ^6.0.0

  # ============ NETWORKING ============
  dio: ^5.3.0
  http: ^1.1.0
  connectivity_plus: ^4.0.0

  # ============ LOCAL STORAGE ============
  hive: ^2.2.0
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.0
  local_auth: ^2.1.0

  # ============ UI & COMPONENTS ============
  flutter_rating_bar: ^4.1.0
  google_maps_flutter: ^2.5.0
  geolocator: ^9.0.0
  image_picker: ^1.0.0
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  
  # ============ CHARTS & GRAPHICS ============
  fl_chart: ^0.65.0
  charts_flutter: ^0.13.0
  intl: ^0.19.0
  syncfusion_flutter_charts: ^23.1.0
  
  # ============ NOTIFICATIONS ============
  firebase_core: ^2.24.0
  firebase_messaging: ^14.6.0
  flutter_local_notifications: ^15.1.0
  
  # ============ PAYMENTS ============
  stripe_android: ^0.10.0
  stripe_ios: ^23.1.0
  pay: ^2.0.0
  
  # ============ UTILITIES ============
  uuid: ^4.0.0
  logger: ^2.0.0
  equatable: ^2.0.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0
  # ============ INTERNATIONALIZATION ============
  flutter_localizations:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter

  # ============ CODE GENERATION ============
  build_runner: ^2.4.0
  riverpod_generator: ^2.0.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  hive_generator: ^2.0.0

  # ============ LINTING ============
  flutter_lints: ^3.0.0
  
  # ============ TESTING ============
  mocktail: ^1.0.0
  integration_test:
    sdk: flutter

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
    - assets/animations/
    - assets/lottie/
  
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
```

---

## 📁 STRUCTURE DES DOSSIERS

```
cargolink/
├── lib/
│   ├── main.dart
│   │
│   ├── app/
│   │   ├── app.dart
│   │   └── routes.dart
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   └── kyc_screen.dart
│   │   │
│   │   ├── client/
│   │   │   ├── client_home_screen.dart
│   │   │   ├── search_screen.dart
│   │   │   ├── booking_wizard_screen.dart
│   │   │   ├── tracking_screen.dart
│   │   │   └── profile_screen.dart
│   │   │
│   │   ├── shipper/
│   │   │   ├── shipper_dashboard_screen.dart
│   │   │   ├── shipments_screen.dart
│   │   │   ├── reservations_screen.dart
│   │   │   ├── revenue_screen.dart
│   │   │   └── settings_screen.dart
│   │   │
│   │   └── admin/
│   │       ├── admin_dashboard.dart
│   │       ├── users_management.dart
│   │       ├── disputes_screen.dart
│   │       └── analytics_screen.dart
│   │
│   ├── components/
│   │   ├── shipper_booking_card.dart
│   │   ├── reservation_ticket.dart
│   │   ├── smart_notification.dart
│   │   ├── tracking_timeline.dart
│   │   ├── dashboard_metrics.dart
│   │   ├── compact_status_card.dart
│   │   ├── revenue_card.dart
│   │   ├── editable_profile_wrapper.dart
│   │   └── ... (10+ other components)
│   │
│   ├── providers/
│   │   ├── cargo_providers.dart
│   │   ├── auth_provider.dart
│   │   ├── user_provider.dart
│   │   └── theme_provider.dart
│   │
│   ├── services/
│   │   ├── cargo_repository.dart
│   │   ├── auth_service.dart
│   │   ├── notification_service.dart
│   │   ├── location_service.dart
│   │   └── payment_service.dart
│   │
│   ├── models/
│   │   ├── user.dart
│   │   ├── shipment.dart
│   │   ├── reservation.dart
│   │   ├── tracking_event.dart
│   │   ├── profile.dart
│   │   └── stats.dart
│   │
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── colors.dart
│   │   ├── typography.dart
│   │   └── spacing.dart
│   │
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── formatters.dart
│   │   ├── responsive.dart
│   │   ├── extensions.dart
│   │   └── constants.dart
│   │
│   └── animations/
│       ├── page_transitions.dart
│       ├── list_animations.dart
│       └── custom_painters.dart
│
├── assets/
│   ├── images/
│   ├── icons/
│   ├── fonts/
│   └── lottie/
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
└── README.md
```

---

## 🔧 CONFIGURATION SUPABASE

### 1. **Créer le projet Supabase**

```bash
# Via dashboard: https://supabase.com
# Créer nouveau projet
# Récupérer: PROJECT_URL, ANON_KEY
```

### 2. **Initialiser dans main.dart**

```dart
// lib/main.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://YOUR_PROJECT.supabase.co',
    anonKey: 'YOUR_ANON_KEY',
    authCallbackUrlScheme: 'com.cargolink',
  );
  
  // Initialize other services
  await initializeServices();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> initializeServices() async {
  // Local storage
  await Hive.initFlutter();
  
  // Notifications
  await initializeNotifications();
  
  // Other services...
}

class MyApp extends ConsumerWidget {
  const MyApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'CargoLink',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: theme,
      home: const AuthenticationWrapper(),
    );
  }
}

// Auth wrapper
class AuthenticationWrapper extends ConsumerWidget {
  const AuthenticationWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const LoginScreen();
        
        // Check user role
        return ref.watch(userRoleProvider).when(
              data: (role) {
                switch (role) {
                  case 'client':
                    return const ClientHomeScreen();
                  case 'shipper':
                    return const ShipperDashboardScreen();
                  case 'admin':
                    return const AdminDashboard();
                  default:
                    return const KYCScreen();
                }
              },
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => const LoginScreen(),
            );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => const LoginScreen(),
    );
  }
}
```

### 3. **Schéma Supabase (SQL)**

```sql
-- Users & Auth
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  role TEXT DEFAULT 'client' CHECK (role IN ('client', 'shipper', 'admin')),
  phone TEXT,
  verified BOOLEAN DEFAULT FALSE,
  kyc_status TEXT DEFAULT 'pending' CHECK (kyc_status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Client Profiles
CREATE TABLE IF NOT EXISTS public.client_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  date_of_birth DATE,
  address TEXT,
  city TEXT,
  postal_code TEXT,
  payment_method TEXT,
  card_last4 TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Shipper Profiles
CREATE TABLE IF NOT EXISTS public.shipper_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  business_name TEXT NOT NULL,
  category TEXT,
  routes TEXT[],
  trust_level INTEGER DEFAULT 1,
  total_shipments INTEGER DEFAULT 0,
  delivery_rate INTEGER DEFAULT 0,
  total_revenue DECIMAL(15, 2) DEFAULT 0,
  bank_account_holder TEXT,
  bank_name TEXT,
  bank_account_last4 TEXT,
  rating DECIMAL(3, 1) DEFAULT 0,
  review_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Shipments
CREATE TABLE IF NOT EXISTS public.shipments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shipper_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  departure_city TEXT NOT NULL,
  arrival_city TEXT NOT NULL,
  departure_date TIMESTAMP WITH TIME ZONE NOT NULL,
  arrival_date_expected TIMESTAMP WITH TIME ZONE,
  available_kg DECIMAL(10, 2) NOT NULL,
  total_kg DECIMAL(10, 2) NOT NULL,
  price_per_kg DECIMAL(10, 2) NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Reservations
CREATE TABLE IF NOT EXISTS public.reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shipper_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  shipment_id UUID NOT NULL REFERENCES public.shipments(id) ON DELETE CASCADE,
  weight DECIMAL(10, 2) NOT NULL,
  product_name TEXT NOT NULL,
  product_description TEXT,
  total_price DECIMAL(15, 2) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'in_transit', 'delivered', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  accepted_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tracking Events
CREATE TABLE IF NOT EXISTS public.tracking_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id UUID NOT NULL REFERENCES public.reservations(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN ('pickup', 'in_transit', 'arrival', 'delivery', 'delay', 'issue')),
  status TEXT NOT NULL,
  event_time TIMESTAMP WITH TIME ZONE NOT NULL,
  location TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  details TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Reviews & Ratings
CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id UUID NOT NULL REFERENCES public.reservations(id) ON DELETE CASCADE,
  reviewer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  reviewed_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shipper_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shipments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tracking_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can read their own profile"
ON public.users FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Shippers can read active shipments"
ON public.shipments FOR SELECT
USING (shipper_id = auth.uid() OR status = 'active');
```

---

## 🚀 QUICK START GUIDE

### 1. **Cloner & Setup**

```bash
# Clone the repo
git clone https://github.com/Connacri/CargoLink.git
cd CargoLink

# Install dependencies
flutter pub get

# Generate code (riverpod, freezed, etc)
flutter pub run build_runner build --delete-conflicting-outputs

# Setup for iOS
cd ios
pod install
cd ..
```

### 2. **Configuration Environnement**

```bash
# Create .env file
cat > .env << EOF
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
GOOGLE_MAPS_API_KEY=YOUR_API_KEY
STRIPE_PUBLISHABLE_KEY=YOUR_STRIPE_KEY
EOF
```

### 3. **Run the app**

```bash
# Debug
flutter run -d chrome # Web
flutter run -d emulator-5554 # Android Emulator
flutter run -d iPhone # iOS Simulator

# Profile (performance testing)
flutter run --profile

# Release
flutter run --release
```

### 4. **Build for Production**

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## ✅ DEPLOYMENT CHECKLIST

### Pre-Launch
- [ ] **Code Quality**
  - [ ] Pas de `print()` en production
  - [ ] Tous les `TODO` résolus
  - [ ] Error handling complet
  - [ ] Logging produit

- [ ] **Performance**
  - [ ] Benchmark: < 3 sec startup
  - [ ] Pas de memory leaks (Profiler)
  - [ ] Animations 60fps
  - [ ] Images optimisées

- [ ] **Security**
  - [ ] API keys en .env (pas hardcodé)
  - [ ] HTTPS forcé
  - [ ] Supabase RLS activée
  - [ ] Auth tokens sécurisés
  - [ ] Pas de données sensibles en logs

- [ ] **Testing**
  - [ ] Unit tests > 80% coverage
  - [ ] Widget tests des components clés
  - [ ] Integration tests (auth, booking)
  - [ ] Manual QA checklist

- [ ] **Infrastructure**
  - [ ] Supabase backups configurés
  - [ ] Firebase configured
  - [ ] Analytics enabled
  - [ ] Error tracking (Sentry)

### Launch Day
- [ ] Release notes rédigées
- [ ] App Store optimisation (screenshots, description)
- [ ] Google Play store setup
- [ ] Social media announcement
- [ ] Support email ready

### Post-Launch
- [ ] Monitor crashes (Sentry)
- [ ] Monitor performance (Firebase)
- [ ] User feedback analysis
- [ ] A/B testing setup
- [ ] Patch release si needed

---

## 📊 ANALYTICS EVENTS À TRACKER

```dart
// lib/services/analytics_service.dart

class AnalyticsService {
  // User events
  static const String userSignup = 'user_signup';
  static const String userLogin = 'user_login';
  static const String kycStarted = 'kyc_started';
  static const String kycCompleted = 'kyc_completed';

  // Shipper events
  static const String shipmentCreated = 'shipment_created';
  static const String shipmentUpdated = 'shipment_updated';
  static const String reservationAccepted = 'reservation_accepted';

  // Client events
  static const String searchInitiated = 'search_initiated';
  static const String bookingStarted = 'booking_started';
  static const String bookingCompleted = 'booking_completed';
  static const String bookingCancelled = 'booking_cancelled';
  
  // Revenue events
  static const String paymentInitiated = 'payment_initiated';
  static const String paymentCompleted = 'payment_completed';
  static const String paymentFailed = 'payment_failed';
}

// Usage
ref.read(analyticsProvider).logEvent(
  AnalyticsService.bookingCompleted,
  {
    'shipment_id': shipmentId,
    'amount': totalPrice,
    'currency': 'DZD',
  },
);
```

---

## 🔍 MONITORING & ERROR TRACKING

```dart
// lib/services/error_tracking.dart

import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> initErrorTracking() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN';
      options.environment = kReleaseMode ? 'production' : 'development';
      options.tracesSampleRate = 1.0;
      options.enableAutoSessionTracking = true;
    },
    appRunner: () => runApp(const MyApp()),
  );
}

// Capture exceptions
try {
  await repository.fetchShipments();
} catch (e, stackTrace) {
  Sentry.captureException(
    e,
    stackTrace: stackTrace,
    withScope: (scope) {
      scope.setTag('feature', 'shipment_search');
      scope.setContext('shipment', {'id': shipperId});
    },
  );
}
```

---

## 📱 APP STORE OPTIMIZATION

### iOS
- App Name: "CargoLink - Cargo Marketplace"
- Keywords: "shipping, cargo, logistics, import, Algeria"
- Category: Lifestyle
- Rating: 4+ (target)
- Min iOS: 12.0
- Permissions:
  - NSLocationWhenInUseUsageDescription
  - NSCameraUsageDescription
  - NSPhotoLibraryUsageDescription

### Android
- Package: com.cargolink.app
- Min SDK: 21
- Target SDK: 34
- Permissions:
  - ACCESS_FINE_LOCATION
  - CAMERA
  - READ_EXTERNAL_STORAGE
  - INTERNET

---

## 🎯 ROADMAP FUTURES

**v1.0** (Current)
- ✅ Core marketplace
- ✅ Booking wizard
- ✅ Real-time tracking

**v1.1** (3 months)
- [ ] Advanced filtering (weather, demand forecast)
- [ ] AI price suggestions
- [ ] Scheduled payments
- [ ] Multi-language (AR, FR, EN)

**v2.0** (6 months)
- [ ] IoT integration (smart tracking)
- [ ] B2B partnerships
- [ ] Insurance options
- [ ] API for developers

**v2.5** (9 months)
- [ ] Blockchain verification
- [ ] DAO governance
- [ ] Global expansion

---

## 📞 SUPPORT & CONTACT

- **Email**: support@cargolink.dz
- **WhatsApp**: +213 xxx xxx xxx
- **Docs**: https://docs.cargolink.dz
- **GitHub**: https://github.com/Connacri/CargoLink

---

**Happy Shipping! 🚚📦**
