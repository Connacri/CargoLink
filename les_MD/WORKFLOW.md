# 📦 CargoLink — Workflow & Fonctionnement de l'App

> Document du fonctionnement réel de l'application (basé sur le code) : rôles, parcours client, parcours expéditeur, parcours admin, statuts et données techniques.

---

## 1. Rôles & Navigation

L'app route par rôle via `lib/app/home_tabs_screen.dart`. Le rôle est défini dans `User.role` (stocké dans Supabase Auth + table `users`).

| Rôle | Écran d'accueil | Permissions |
|---|---|---|
| `client` | Tabs client (Accueil, Mes commandes, Profil) | Réserver du poids, payer, suivre, annuler |
| `shipper` | `ShipperDashboardScreen` | Publier des offres, gérer les commandes reçues |
| `admin` | `AdminDashboardScreen` | Vérifier les expéditeurs, litiges, revenus, annonces |
| `super_admin` | `SuperAdminDashboardScreen` | Contrôle total (comptes, rôles, modération) |

- `lib/screens/auth/role_selection_screen.dart` : choisit le rôle à la création de profil (`createProfileWithRole`) et permet de changer de rôle plus tard (`changeMyRole`).
- Un utilisateur **admin/super_admin** ne passe pas par `home_tabs` : il est dirigé directement vers le dashboard correspondant.

---

## 2. Parcours Client

### 2.1 Inscription & rôle
1. Signup / login (email ou Google) → `auth_service.signUpWithEmail(...)`.
2. Choix du rôle **« Client »** dans l'écran de sélection de rôle.
3. Complétion du profil (nom, téléphone, photo).

### 2.2 Trouver une offre (`client_home_screen.dart`)
- Liste paginée (`clientShipmentsPagerProvider`, 20/par page) des **shipments actifs**.
- **Recherche serveur** (`searchShipments` + `clientSearchPagerProvider`) et filtres (destination, origine).
- Bandeau d'accueil + carte « Trouvez les meilleurs micro-importateurs ».
- Pull-to-refresh.

### 2.3 Réserver du poids (`booking_screen.dart`)
Depuis le détail d'une offre, bouton **« Réserver »** → route `/booking` avec `shipment.id`.

Le formulaire collecte :
- Nom du produit
- Description
- Poids demandé (kg) — limité à `AppConstants.maxWeightKg` (50 kg)
- Photos du produit (via `file_picker`, upload Supabase Storage bucket `bookings`)

À la soumission, `BookingService.createBooking` (`booking_payment_service.dart`) :
1. **Vérifie** que le poids demandé est valide (0,1 → 50 kg) et que l'expéditeur est **vérifié** par l'admin.
2. Vérifie qu'il reste du poids disponible sur l'offre.
3. Calcule `allocatedWeight = calculateAllocationWeight(requested, remaining)`.
4. Calcule `totalPrice = allocatedWeight × pricePerKg`.
5. Crée le booking (`status = pending`, `payment_status = pending`).
6. **Réserve le poids** sur le shipment (`updateReservedWeight`).
7. Crée l'enregistrement de **paiement** (`status = pending`).
8. Navigation → `/payment` avec `booking.id` (`pushReplacementNamed`).

### 2.4 Paiement (`payment_screen.dart`)
- Affiche le **total** (poids alloué × prix/kg) en **DZD**.
- Choix de la méthode de paiement (défaut : **cash**).
- `PaymentService.completePayment(paymentId, 'tx_<epochMs>', paymentMethod)` :
  - paiement `status = completed` + `transaction_id` + `payment_method`
  - booking `payment_status = paid`
- Après paiement → écran de suivi `/tracking`.

### 2.5 Mes commandes (`my_orders_screen.dart`)
Liste paginée des bookings du client avec **filtres de statut** :
- **Suivre** → `/tracking` (timeline + barre de progression)
- **Annuler** (uniquement si `status = pending` ou `payment_status = pending`) :
  - `cancelBooking` **libère le poids réservé** et **rembourse** le paiement (`refundPayment` → `refunded`).

### 2.6 Suivi en temps réel (`tracking_screen.dart`)
8 étapes chronologiques type DHL/UPS :

```
order_processed → collected → departed_origin → in_transit
→ arrived_destination → customs_cleared → out_for_delivery → delivered
```

- Barre de progression basée sur l'étape courante.
- Timeline via `trackingHistoryProvider` + écoute temps réel (`listenToTrackingUpdates`, Supabase Realtime).

---

## 3. Parcours Expéditeur (micro-importateur)

### 3.1 Inscription & vérification (KYC)
1. Signup / login → rôle **« Expéditeur »** → profil avec documents (KYC : passeport + live photo, upload bucket `documents`).
2. L'expéditeur doit être **vérifié** par un admin :
   - Dashboard bloqué tant que `shipper.isVerified == false` (« Vérification en attente »).
   - Si rejeté : écran « Dossier rejeté » avec la raison (`rejectionReason`).
   - Règle métier côté client : impossible de réserver sur une offre d'un expéditeur non vérifié.

### 3.2 Publier une offre (`_showPublishDialog`)
Bouton **« Publier une offre »** / « Publier » → `ShipmentService.publishShipment` :

| Champ | Contraintes |
|---|---|
| Origine | `AppConstants.populateOrigins` (Turquie, Chine, Dubaï, France, Italie, Espagne) |
| Destination | `AppConstants.majorCities` (Alger, Oran, Annaba, …) |
| Poids disponible | > `minWeightKg` (0,1 kg) |
| Prix par kg (DZD) | ≥ `minPricePerKg` (500 DZD) |
| N° de vol | optionnel |
| Description | optionnelle |
| Départ / Arrivée | date picker (départ ≥ aujourd'hui, arrivée ≥ départ) |

L'offre est créée en statut **`active`**.

### 3.3 Tableau de bord (`shipper_dashboard_screen.dart`)
- **Stats** (4 cartes) : Chiffre d'affaires (`shipperEarningsProvider` = total des bookings `delivered` + `paid`), Offres, Commandes, Offres actives.
- **Filtres** de statut : Toutes / Actives (`active`) / Terminées (`completed`) / Annulées (`cancelled`).
- Liste paginée « Mes offres ».

### 3.4 Gérer les commandes (`ShipperShipmentDetailScreen`)
Chaque offre ouvre un détail : **résumé poids** (total / réservé / restant + barre d'utilisation) + **prix/kg** + liste paginée « Commandes reçues ».

Cartes de commande (`_ManageBookingCard`) selon le statut du booking :

| Statut booking | Actions expéditeur | Effets |
|---|---|---|
| `pending` | **Confirmer** / **Refuser** | Confirmer → `confirmed` ; Refuser → `cancelBooking` (poids libéré + remboursement) |
| `confirmed` | **Marquer expédié** / **Annuler** | `shipped` + event tracking `departed_origin` + notification client « Colis expédié » |
| `shipped` | **Marquer livré** | `delivered` + event tracking `delivered` + notification client « Colis livré » |

---

## 4. Parcours Admin / Super Admin

### 4.1 Admin (`admin_dashboard_screen.dart`)
« Administration — Vérification, litiges et revenus »
- **Vérifier / rejeter** les expéditeurs (KYC).
- **Litiges** ouverts (`openDisputesPagerProvider`).
- **Revenus** (`getRevenueStats` : CA, transactions, panier moyen).
- **Annonces** (`broadcast_screen.dart`) : diffuser à tous les utilisateurs.

### 4.2 Détail utilisateur (`user_details_screen.dart`)
Drill-down par tabs : Dossier expéditeur, Shipments, Bookings, Payments, Litiges. Actions : changer le rôle, supprimer définitivement le compte (Edge Function `delete-account` purge Firebase + DB).

### 4.3 Listes globales (`entity_list_screen.dart`)
`EntityListType { users, shipments, bookings, payments, disputes }` — listes paginées avec recherche et drill-down. RLS `admin_read_all_entities` limite ces accès aux admin/super_admin.

### 4.4 Super Admin (`super_admin_dashboard_screen.dart`)
Contrôle total : gestion des comptes, changements de rôle, suppression définitive, vérification des expéditeurs, litiges, annonces, listes de toutes les entités.

---

## 5. Statuts & Cycle de vie

### Booking (`bookings.status`)
```
pending → confirmed → shipped → delivered
   │          │           │
   └── cancelled (à tout moment, remboursement + poids libéré)
```

### Paiement (`payments.status`)
```
pending → completed (paid)
   └────→ refunded  (annulation/litige client)
```

### Shipment (`shipments.status`)
```
active → completed | cancelled
```

### Litige (`disputes.status`)
```
open → investigating → resolved | rejected
```
- `resolveInFavorOfClient` → **remboursement** + statut `resolved`.
- Types de litiges : `fraud`, `customs_seizure`, `damage`, …
- ⚠️ `DisputeService.createDispute` existe côté service mais **aucun bouton client ne l'appelle encore** dans les écrans refondus (à reconnecter).

---

## 6. Notifications

Service `NotificationService` (dans `tracking_dispute_service.dart`) + Supabase Realtime :
- `notifyShipperBookingConfirmed` → expéditeur quand un booking passe `confirmed`.
- `notifyClientShipmentDispatched` → client « Votre colis a été expédié ».
- `notifyClientShipmentDelivered` → client « Colis livré avec succès ».
- `listenToNotifications(userId)` : notifications en temps réel.
- Notifications push FCM : service `fcm_service.dart` présent (à finaliser).

---

## 7. Données techniques clés

| Élément | Valeur |
|---|---|
| Devise | `DZD` (defaultCurrency) |
| Commission plateforme | 5 % (`platformCommissionPercent`) |
| Poids min / max par booking | 0,1 kg / 50 kg |
| Prix min / kg | 500 DZD |
| Origines | Turquie, Chine, Dubaï, France, Italie, Espagne |
| Destinations | Alger, Oran, Annaba, Constantine, Tlemcen, Sidi Bel Abbès, Béjaïa, Tizi Ouzou, Batna, Blida |
| Pagination | 20/par page par défaut (15 pour dashboards shipper) |

### Flux UI principaux
- Recherche d'offres → `/booking` (shipment.id) → `/payment` (booking.id) → `/tracking` (booking.id)
- Suivi : `/tracking` ; Annulation : `my_orders` (seulement si `pending` ou paiement `pending`)
- Publication offre : `shipper_dashboard` → bottom sheet → offre `active`

### Services (`lib/data/services/`)
| Service | Rôle |
|---|---|
| `auth_service.dart` | Inscription, login, Google, profils, rôles |
| `shipper_shipment_service.dart` | Shipments (actifs, par expéditeur, recherche, publication) |
| `booking_payment_service.dart` | Bookings + paiements + remboursements + revenus |
| `tracking_dispute_service.dart` | Tracking, litiges, notifications |
| `storage_service.dart` | Upload photos (profiles, documents, bookings, disputes) |
| `broadcast_service.dart` | Annonces admin |
| `fcm_service.dart` | Push notifications (à finaliser) |
