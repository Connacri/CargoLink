# 📋 CargoLink — Workflows & Règles Métier par Rôle

> Document de référence (basé sur le code) détaillant, pour **chaque rôle**, les workflows pas-à-pas, les règles métier applicables, les transitions de statut et les accès RLS. Complémentaire de `les_MD/WORKFLOW.md` (vue globale) : ici chaque rôle est traité individuellement et exhaustivement.

---

## Sommaire

1. [Rôles & accès](#1-rôles--accès)
2. [Règles transverses (tous rôles)](#2-règles-transverses-tous-rôles)
3. [Client](#3-client)
4. [Expéditeur (micro-importateur)](#4-expéditeur-micro-importateur)
5. [Admin](#5-admin)
6. [Super Admin](#6-super-admin)
7. [Statuts & transitions](#7-statuts--transitions)
8. [Annexe : données techniques](#8-annexe--données-techniques)

---

## 1. Rôles & accès

| Rôle | Valeur DB (`users.role`) | Dashboard | Écran d'accueil |
|---|---|---|---|
| Client | `client` | — | Onglets client (Accueil, Mes commandes, Profil) |
| Expéditeur | `shipper` | `ShipperDashboardScreen` | Dashboard expéditeur |
| Admin | `admin` | `AdminDashboardScreen` | 4 onglets (Expéditeurs, Litiges, Revenus, Inventaire) |
| Super Admin | `super_admin` | `SuperAdminDashboardScreen` | Dashboard fondateur |

Règles :
- Le rôle est stocké dans `users.role` (Supabase Auth + table `users`).
- `UserRole` (enum) ne connaît que `client`, `shipper`, `admin` ; `super_admin` est géré comme **chaîne brute** (`'super_admin'`) dans le routage.
- Le routage se fait dans `lib/app/home_tabs_screen.dart` : admin/super_admin sont dirigés directement vers leur dashboard (ils ne passent pas par les onglets client).
- **Changement de rôle auto** (`changeMyRole` dans `auth_service.dart:691`) : limité à `client ↔ shipper`. Il est **impossible** de s'auto-attribuer un rôle admin/super_admin.
- **Changement de rôle par un admin/super_admin** (`updateUserRole`, `auth_service.dart:836`) : n'importe quel utilisateur peut voir son rôle changé. `super_admin` lui-même ne peut être créé/supprimé que par action manuelle super_admin.

---

## 2. Règles transverses (tous rôles)

1. **RLS activée partout** : les policies filtrent par `auth.uid()` + rôle dans `users.role`. Aucun accès sans authentification.
2. **Pagination obligatoire** : toute liste = `PaginatedListNotifier` + `PagedSliverList/Grid` (règle n°1 de `docs/ui_refonte.md`).
3. **Temps réel** : les tables métier sont publiées sur `supabase_realtime` ; les listes se mettent à jour « en place » (patch) sans rechargement.
4. **Devise** : `DZD`. **Commission plateforme** : 5 %.
5. **Poids par réservation** : min 0,1 kg — max 50 kg (`AppConstants.maxWeightKg`).
6. **Prix minimum** : 500 DZD/kg (`AppConstants.minPricePerKg`).
7. **UI en français** (`Locale('fr')`).

---

## 3. Client

### 3.1 Inscription
1. Signup/login email ou Google (`auth_service.signUpWithEmail`) → choix du rôle **« Client »** (`role_selection_screen.dart`).
2. Complétion du profil (nom, téléphone, photo).

### 3.2 Trouver une offre (`client_home_screen.dart`)
1. Liste paginée des **shipments actifs** (`clientShipmentsPagerProvider`, 20/page).
2. Recherche serveur + filtres (destination, origine) ; pull-to-refresh.
3. **Règle** : seules les offres `active` des expéditeurs **vérifiés** sont visibles/réservables.

### 3.3 Réserver du poids (`booking_screen.dart`)
1. Bouton **« Réserver »** sur une offre → `/booking?shipmentId=...`.
2. Formulaire : nom du produit, description, poids demandé (0,1→50 kg), photos (upload bucket `bookings`).
3. À la soumission, `createBooking` :
   - valide le poids et la vérification de l'expéditeur ;
   - calcule `allocatedWeight = calculateAllocationWeight(requested, remaining)` ;
   - calcule `totalPrice = allocatedWeight × pricePerKg` ;
   - crée le booking (`status = pending`, `payment_status = pending`) ;
   - **réserve le poids** sur le shipment (`updateReservedWeight`) ;
   - crée l'enregistrement de paiement (`status = pending`) ;
   - navigation → `/payment`.
4. **Règles** :
   - impossible de réserver plus que le poids restant (sinon allocation partielle) ;
   - impossible de réserver sur un expéditeur non vérifié ;
   - un même client ne peut pas s'auto-réserver (pas applicable : client ≠ expéditeur).

### 3.4 Payer (`payment_screen.dart`)
- Total en DZD, choix de la méthode (Espèces / Virement / CCP-CIB / Chargily EDAHABIA-carte / Stripe).
- `completePayment(paymentId, 'tx_<epochMs>', method)` → `payments.status = completed`, `bookings.payment_status = paid`.
- **Règle** : paiement possible avant ou après confirmation de l'expéditeur (le statut se met à jour en direct).

### 3.5 Mes commandes (`my_orders_screen.dart`)
- Filtres par statut ; actions :
  - **Suivre** → `/tracking`.
  - **Annuler** : uniquement si `status = pending` **ou** `payment_status = pending`. Effet : `cancelBooking` libère le poids réservé + **rembourse** (`refundPayment` → `refunded`).
- **Règle** : une commande déjà `confirmed`/`shipped`/`delivered` **ne peut plus être annulée** par le client.

### 3.6 Suivi (`tracking_screen.dart`)
- Timeline 8 étapes + barre de progression + temps réel (`trackingHistoryProvider` + `listenToTrackingUpdates`).
- À la livraison : **confirmation de réception** (photo) + **notation de l'expéditeur**.

### 3.7 Litiges & chat
- **Litige** : signalement (fraude, saisie douane, endommagé, non livré, autre). *Note* : le service `createDispute` existe ; à reconnecter dans les écrans refondus si besoin.
- **Chat** avec l'expéditeur : statuts envoyé / délivré / lu, push FCM.

---

## 4. Expéditeur (micro-importateur)

### 4.1 Inscription & KYC
1. Rôle **« Expéditeur »** → dépôt des documents KYC (passeport + **live selfie** avec détection de visage ML Kit ; upload bucket `documents`).
2. **Vérification obligatoire** par un admin :
   - Dashboard bloqué si `shipper.isVerified == false` (« Vérification en attente ») ;
   - si rejeté : écran « Dossier rejeté » avec `rejectionReason` ;
   - **règle** : aucun client ne peut réserver sur une offre d'un expéditeur non vérifié.
3. Le dossier est modifiable et re-vérifiable.

### 4.2 Publier une offre
Bouton **« Publier une offre »** → `publishShipment` :

| Champ | Contrainte |
|---|---|
| Origine | `AppConstants.populateOrigins` (Turquie, Chine, Dubaï, France, Italie, Espagne) |
| Destination | `AppConstants.majorCities` (Alger, Oran, Annaba, Constantine, Tlemcen, Sidi Bel Abbès, Béjaïa, Tizi Ouzou, Batna, Blida) |
| Poids disponible | > 0,1 kg |
| Prix/kg | ≥ 500 DZD |
| N° de vol | optionnel |
| Description | optionnelle |
| Dates départ/arrivée | départ ≥ aujourd'hui, arrivée ≥ départ |

- L'offre est créée en **`active`**.

### 4.3 Dashboard & gestion des commandes
- **Stats** : CA (bookings `delivered` + `paid`), offres, commandes, offres actives.
- Filtres statut : Toutes / `active` / `completed` / `cancelled`.
- Dans le détail d'une offre (`ShipperShipmentDetailScreen`) : résumé poids (total/réservé/restant) + liste « Commandes reçues ».

| Statut booking | Actions expéditeur | Effets |
|---|---|---|
| `pending` | **Confirmer** / **Refuser** | → `confirmed` ; Refuser → `cancelBooking` (poids libéré + remboursement) |
| `confirmed` | **Marquer expédié** / **Annuler** | → `shipped` + event `departed_origin` + notification client |
| `shipped` | **Marquer livré** | → `delivered` + event `delivered` + notification client |
| `delivered` | — | fin de cycle ; le CA est comptabilisé |

- **Règle** : le poids réservé reste bloqué jusqu'à annulation ou livraison.

### 4.4 Revenus & statistiques
- `ShipperFinanceScreen` : CA total, revenus disponibles, commissions (5 %), historique des transactions, graphique.
- Confirmation des commissions : `awaiting_confirmation` → confirmée par un admin/super_admin.

---

## 5. Admin

### 5.1 Dashboard (`admin_dashboard_screen.dart`)
4 onglets : **Expéditeurs · Litiges · Revenus · Inventaire**.

### 5.2 Onglet Expéditeurs
- **Centre de vérification KYC** : approuver / rejeter (avec raison) / re-vérifier les expéditeurs.
- Accès limité par RLS `admin_read_all_entities`.

### 5.3 Onglet Litiges
- Liste des litiges ouverts ; résolution :
  - `resolveInFavorOfClient` → **remboursement** + statut `resolved` ;
  - `rejected` sinon ;
  - flag de l'expéditeur en cas de fraude (`shipper_flags`).

### 5.4 Onglet Revenus
- `getRevenueStats` : CA, transactions, panier moyen ; `transactions_screen.dart` : comptabilité (allocations de paiement, payouts).
- **Confirmation des commissions** expéditeur (`awaiting_confirmation` → confirmée).

### 5.5 Onglet Inventaire (nouveau)
- Gère les **dépôts** (magasins de collecte des colis) : CRUD (`InventoryService`, RLS admin/super_admin).
- `inventory_screen.dart` : liste des dépôts + stats (colis stockés / dispatchés / retournés, poids stocké).
- `depot_detail_screen.dart` : inventaire d'un dépôt — ajouter / modifier / supprimer des colis, changer le statut (`stored` / `dispatched` / `returned`), référence, destinataire, notes, poids.
- **Règle** : les dépôts sont **lisibles par tous les utilisateurs authentifiés** (points de collecte visibles), mais l'**inventaire** (`depot_items`) est réservé aux admin/super_admin.

### 5.6 Autres capacités admin
- **Annonces / broadcasts** ciblés par rôle (client/shipper/admin/super_admin/fondateur).
- **Feedback inbox** (retours utilisateurs avec capture dessinée).
- **Paramètres plateforme** : commission, payouts, devise.
- **Listes globales** (`entity_list_screen.dart`) : users, shipments, bookings, payments, disputes — avec drill-down.
- **Détail utilisateur** : changer le rôle, supprimer définitivement le compte (Edge Function `delete-account`).

---

## 6. Super Admin

`super_admin_dashboard_screen.dart` — contrôle total, sections :

1. **Statistiques globales** : nombre d'utilisateurs, expéditeurs, admins, revenus, litiges (résumés).
2. **Gestion des comptes** : lister tous les utilisateurs, **changer les rôles**, activer/désactiver, **supprimer définitivement** (Edge Function `delete-account`), factory reset (Edge Function `admin-reset`).
3. **Vérification des expéditeurs** (KYC) : approuver / rejeter / re-vérifier.
4. **Litiges** : résolution, remboursement, flags.
5. **Annonces** : broadcasts à toutes les audiences.
6. **Inventaire** : raccourci vers les dépôts / inventaire des colis.
7. **Feedback** : inbox des retours utilisateurs.
8. **Paramètres plateforme** : commission, payouts, devise.
9. **Analytics fondateur** (`founder_analytics_screen.dart`) : métriques avancées.

Règles :
- Actions réservées super_admin : suppression définitive d'utilisateurs, factory reset.
- Les annonces voient « Admin » / « Fondateur » comme audiences.

---

## 7. Statuts & transitions

### Booking (`bookings.status`)
```
pending → confirmed → shipped → delivered
   │          │           │
   └── cancelled (à tout moment ; poids libéré + remboursement si payé)
```

### Paiement (`payments.status` / `bookings.payment_status`)
```
payments.status   : pending → completed | refunded
bookings.payment_status : pending → paid | refunded
```

### Shipment (`shipments.status`)
```
active → completed | cancelled
```

### Litige (`disputes.status`)
```
open → investigating → resolved | rejected
```

### Tracking (événements, ordre chronologique)
```
order_processed → collected → departed_origin → in_transit
→ arrived_destination → customs_cleared → out_for_delivery → delivered
```

### Colis d'inventaire (`depot_items.status`)
```
stored → dispatched | returned
```

### Vérification expéditeur (`shippers.verification_status`)
```
pending → verified | rejected  (re-vérifiable)
```

---

## 8. Annexe : données techniques

| Élément | Valeur |
|---|---|
| Devise | `DZD` |
| Commission | 5 % |
| Poids min/max par booking | 0,1 kg / 50 kg |
| Prix min/kg | 500 DZD |
| Origines | Turquie, Chine, Dubaï, France, Italie, Espagne |
| Destinations | Alger, Oran, Annaba, Constantine, Tlemcen, Sidi Bel Abbès, Béjaïa, Tizi Ouzou, Batna, Blida |
| Pagination | 20/page (15 dashboards shipper) |
| Realtime | tables métier publiées sur `supabase_realtime` |
| Buckets Storage | `profiles`, `documents`, `bookings`, `proofs` |

### Flux UI principaux
- Client : recherche → `/booking` → `/payment` → `/tracking` ; annulation depuis `/my_orders`.
- Expéditeur : `/shipper` dashboard → publier (bottom sheet) → gérer commandes → suivi.
- Admin : `/admin` (4 onglets) ; Super Admin : `/super-admin`.

### Services (`lib/data/services/`)
| Service | Rôle |
|---|---|
| `auth_service.dart` | Auth, profils, rôles, gestion comptes (admin/super_admin) |
| `shipper_shipment_service.dart` | Offres/shipments |
| `booking_payment_service.dart` | Bookings, paiements, remboursements, revenus, commissions |
| `tracking_dispute_service.dart` | Tracking, litiges, notifications |
| `inventory_service.dart` | Dépôts + inventaire de colis (admin/super_admin) |
| `storage_service.dart` | Upload photos |
| `broadcast_service.dart` | Annonces |
| `feedback_service.dart` | Feedback inbox |
| `settings_service.dart` | Paramètres plateforme |
| `fcm_service.dart` | Push notifications |
| `realtime_service.dart` | Canaux temps réel |