# CargoLink - Architecture Complète

## 📁 Arborescence du Projet

```
cargolink/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── config/
│   │   ├── supabase_config.dart
│   │   ├── app_theme.dart
│   │   └── constants.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── shipper_model.dart
│   │   ├── shipment_model.dart
│   │   ├── booking_model.dart
│   │   ├── dispute_model.dart
│   │   └── notification_model.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── shipper_service.dart
│   │   ├── shipment_service.dart
│   │   ├── booking_service.dart
│   │   ├── payment_service.dart
│   │   ├── notification_service.dart
│   │   ├── location_service.dart
│   │   └── storage_service.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── shipper_provider.dart
│   │   ├── shipment_provider.dart
│   │   └── booking_provider.dart
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   ├── shipper_registration_screen.dart
│   │   │   └── verification_screen.dart
│   │   ├── client/
│   │   │   ├── home_screen.dart
│   │   │   ├── available_shipments_screen.dart
│   │   │   ├── booking_screen.dart
│   │   │   ├── my_orders_screen.dart
│   │   │   ├── tracking_screen.dart
│   │   │   └── profile_screen.dart
│   │   ├── shipper/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── publish_shipment_screen.dart
│   │   │   ├── active_shipments_screen.dart
│   │   │   ├── orders_screen.dart
│   │   │   └── profile_screen.dart
│   │   ├── admin/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── verify_shippers_screen.dart
│   │   │   ├── manage_disputes_screen.dart
│   │   │   └── analytics_screen.dart
│   │   └── common/
│   │       ├── dispute_screen.dart
│   │       └── payment_screen.dart
│   └── widgets/
│       ├── custom_app_bar.dart
│       ├── shipment_card.dart
│       ├── booking_card.dart
│       └── loading_widget.dart
├── assets/
│   ├── images/
│   └── icons/
└── android/
    └── app/
        └── src/
            └── main/
                └── AndroidManifest.xml
```

## 🗄️ Schéma Supabase

### Tables Principales

**users**
- id (UUID, PK)
- email (string)
- phone (string)
- full_name (string)
- profile_picture_url (string)
- role (enum: client, shipper, admin)
- created_at (timestamp)
- updated_at (timestamp)

**shippers** (Micro-importateurs)
- id (UUID, PK)
- user_id (FK → users)
- passport_number (string)
- passport_photo_url (string)
- live_photo_url (string)
- verification_status (enum: pending, verified, rejected)
- rejection_reason (text)
- verified_by_admin (UUID, FK → users)
- verified_at (timestamp)
- rating (float, 0-5)
- total_shipments (int)
- created_at (timestamp)

**shipments** (Offres de transport)
- id (UUID, PK)
- shipper_id (FK → shippers)
- origin_country (string)
- destination_city (string, Algérie)
- available_weight_kg (float)
- reserved_weight_kg (float, default 0)
- price_per_kg (float)
- departure_date (timestamp)
- arrival_date (timestamp)
- flight_number (string)
- status (enum: active, completed, cancelled)
- description (text)
- created_at (timestamp)
- updated_at (timestamp)

**bookings** (Réservations des clients)
- id (UUID, PK)
- shipment_id (FK → shipments)
- client_id (FK → users)
- product_name (string)
- product_description (text)
- product_photos_url (array)
- requested_weight_kg (float)
- allocated_weight_kg (float, auto-calculated)
- total_price (float)
- status (enum: pending, confirmed, shipped, delivered, cancelled)
- payment_status (enum: pending, paid, refunded)
- created_at (timestamp)
- updated_at (timestamp)

**shipment_tracking**
- id (UUID, PK)
- booking_id (FK → bookings)
- latitude (float)
- longitude (float)
- status (enum: collected, in_transit, customs_cleared, delivered)
- timestamp (timestamp)
- notes (text)

**disputes**
- id (UUID, PK)
- booking_id (FK → bookings)
- reported_by_user_id (FK → users)
- type (enum: fraud, customs_seizure, damage, non_delivery, other)
- description (text)
- evidence_photos_url (array)
- status (enum: open, investigating, resolved, rejected)
- resolution (text)
- created_at (timestamp)
- resolved_at (timestamp)

**notifications**
- id (UUID, PK)
- user_id (FK → users)
- type (enum: booking_confirmed, shipment_dispatched, tracking_update, payment_confirmed, dispute_update)
- title (string)
- message (text)
- related_booking_id (UUID)
- is_read (boolean, default false)
- created_at (timestamp)

**payments**
- id (UUID, PK)
- booking_id (FK → bookings)
- amount (float)
- currency (string, default 'DZD')
- status (enum: pending, completed, failed, refunded)
- payment_method (string)
- transaction_id (string)
- created_at (timestamp)

## 🔐 RLS Policies (Row Level Security)

```sql
-- Users peuvent voir leur propre profil
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

-- Shippers peuvent voir leurs shipments
CREATE POLICY "Shippers can view own shipments" ON shipments
  FOR SELECT USING (
    shipper_id IN (
      SELECT id FROM shippers WHERE user_id = auth.uid()
    )
  );

-- Clients peuvent voir leurs bookings
CREATE POLICY "Clients can view own bookings" ON bookings
  FOR SELECT USING (client_id = auth.uid());

-- Admin peut voir tous les disputes
CREATE POLICY "Admin can view all disputes" ON disputes
  FOR SELECT USING (
    (SELECT role FROM users WHERE id = auth.uid()) = 'admin'
  );
```

## 📱 Fonctionnalités Clés

### Client
- ✅ Rechercher des micro-importateurs actifs
- ✅ Filtrer par destination, prix, date
- ✅ Réserver du poids avec détails produit
- ✅ Suivre en temps réel la livraison
- ✅ Signaler des problèmes/disputes
- ✅ Paiement sécurisé

### Micro-importateur
- ✅ S'inscrire avec KYC (photo live + passeport)
- ✅ Publier disponibilité de poids
- ✅ Gérer les commandes reçues
- ✅ Mettre à jour le suivi GPS
- ✅ Recevoir paiement après livraison

### Admin
- ✅ Vérifier les micro-importateurs
- ✅ Gérer les disputes et fraudes
- ✅ Voir les analytics
- ✅ Modérer le contenu

## 🛠️ Technologies

- **Frontend**: Flutter 3.x
- **Backend**: Supabase (PostgreSQL)
- **Auth**: Supabase Auth + Google Sign-in
- **Storage**: Supabase Storage
- **Real-time**: Supabase Realtime
- **Paiement**: Chardly/PayPal (intégration)
- **GPS**: Google Maps + Geolocator
- **État**: Riverpod
- **Notifications**: Firebase Cloud Messaging
