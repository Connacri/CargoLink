# 📦 CargoLink V2

## Réseau logistique collaboratif — Multi-Shipper, Chain of Custody, Tracking, Douane, Litiges & Règlement financier

> **Document de référence fonctionnel et UX**
>
> CargoLink permet à un client d'expédier une marchandise en utilisant la capacité disponible dans les bagages de voyageurs / micro-importateurs.
>
> Une expédition peut être transportée par **un ou plusieurs Shippers**, et un Shipper peut transmettre **la totalité ou seulement une partie** de la marchandise à un autre Shipper.
>
> Le système conserve une **chaîne de garde complète, cryptographiquement vérifiable**, depuis la création de l'expédition jusqu'à la livraison finale — au même niveau d'exigence qu'un réseau de fret international (DHL, FedEx, UPS), adapté à un modèle P2P décentralisé.

---

# 1. Principe fondamental

CargoLink ne fonctionne pas comme un service linéaire :

```text
Client
  ↓
Shipper A
  ↓
Destination
```

mais comme un **réseau logistique maillé**, où la marchandise change de porteur autant de fois que nécessaire, chaque changement étant tracé et responsabilisé individuellement.

```text
                       CARGOLINK
                           │
                           ▼
                     EXPÉDITION
                           │
             ┌─────────────┴─────────────┐
             │                           │
          20 kg                        10 kg
             │                           │
             ▼                           ▼
        SHIPPER A                    SHIPPER B
       Alger → Paris                Alger → Madrid
             │                           │
             ▼                           ▼
        12 kg restant                 8 kg
             │
             ▼
        SHIPPER C
       Paris → Madrid
             │
             ▼
        DESTINATION
```

Une même expédition peut donc suivre plusieurs topologies :

```text
DIRECTE            A → Destination
MULTI-SHIPPER       A → B → Destination
SPLIT                A → B
                     A → C
SPLIT + MERGE        A → B
                     A → C
                     B + C → D
REROUTED             A → B → C → Destination
```

### Ce que l'original ne couvrait pas

L'original décrivait ces topologies mais ne posait aucune limite. Un réseau ouvert peut générer des chaînes de garde arbitrairement longues (10, 20 sauts), ce qui devient un vecteur de fraude (dilution de responsabilité) et un problème de performance (requêtes récursives). **CargoLink V2 impose une profondeur maximale de chaîne configurable** (par défaut : 5 sauts), au-delà de laquelle toute nouvelle demande de transfert nécessite une validation Admin explicite. Ce plafond s'inspire directement des limites de hop count utilisées en routage réseau (BGP, OSPF) pour éviter les boucles et la divergence — appliqué ici à une chaîne de responsabilité plutôt qu'à des paquets.

---

# 2. Les quatre concepts centraux

## 2.1 Shipment

La marchandise globale du Client.

```text
SHIPMENT
CLX-2026-000184
```

## 2.2 Booking

La réservation d'une capacité auprès d'un Shipper, à un instant donné, sur un trajet donné.

```text
BOOKING
8 kg — Shipper A — Trip #4471
```

## 2.3 Shipment Leg

Une portion physique du trajet, sous la responsabilité d'un seul Shipper actif à la fois.

```text
LEG 1
Alger → Paris
Shipper A
```

## 2.4 Package / Parcel

L'unité physique traçable individuellement.

```text
SHIPMENT
  ├── PACKAGE A — 10 kg
  ├── PACKAGE B — 8 kg
  └── PACKAGE C — 12 kg
```

### Règle d'identification

Le poids n'est jamais un identifiant. Chaque colis porte :

```text
package_id            — UUID interne, immuable
package_tracking_code — CLX-2026-000184-01, lisible et public
package_fingerprint   — hash du contenu déclaré (poids, description, valeur, photos) figé à la création
```

Le `package_fingerprint` est nouveau par rapport à l'original : c'est ce qui permet de prouver, en cas de litige, qu'un colis remis au Leg 3 correspond bien à celui déclaré au Leg 1 — sans dépendre uniquement de la bonne foi des déclarations successives.

---

# 3. Chain of Custody

Chaque transfert de possession produit un événement **append-only, horodaté, signé**.

```text
CLIENT → SHIPPER A → SHIPPER B → SHIPPER C → DESTINATAIRE
```

```text
HANDOVER
from_actor
to_actor
package_ids[]
weight
timestamp (serveur, jamais client)
latitude / longitude
verification_method
proof_id
chain_hash          ← nouveau : hash de l'événement précédent + cet événement
signature_from
signature_to
```

### chain_hash — pourquoi

C'est l'apport le plus important de cette réécriture (détaillé en §31bis). Chaque `HANDOVER` inclut le hash cryptographique du `HANDOVER` précédent de ce colis. La chaîne de garde devient ainsi vérifiable comme une chaîne de blocs : falsifier un événement au milieu de la chaîne casse tous les hashs suivants, ce qui rend une falsification a posteriori détectable même par un audit hors-ligne, sans dépendre de la disponibilité du serveur au moment de l'incident.

---

# 4. Transfert total

```text
A possède 10 kg → remet 10 kg à B
```

Événement : `FULL_HANDOVER`. Après transfert : `A = 0 kg`, `B = 10 kg`.

---

# 5. Transfert partiel

```text
A possède 20 kg → remet 8 kg à B
```

Après transfert : `A = 12 kg`, `B = 8 kg`. L'expédition (`CLX-2026-000184`) reste identique ; ce sont les legs qui se subdivisent :

```text
LEG 1 (A, 12 kg, Alger → Paris)
LEG 2 (A, 8 kg, Alger → Paris) → LEG 3 (B, 8 kg, Paris → Madrid)
```

---

# 6. Transfert partiel d'un colis (sélection par colis)

```text
PACKAGE A — 5 kg
PACKAGE B — 3 kg
PACKAGE C — 12 kg
```

A peut transmettre A + B (8 kg) à B sans toucher C. C'est le mode de transfert **recommandé par défaut** dans l'UX (voir §99) car il élimine toute ambiguïté sur "quel poids appartient à quel colis" — contrairement à un transfert par poids brut qui oblige le système à déduire une répartition.

---

# 7. Colis indivisible

```text
PACKAGE A — 1 colis, 20 kg, is_divisible = false
```

Transférable en 0 kg ou 20 kg, jamais une fraction. Le champ `is_divisible` est déclaré à la création du package et **verrouillé** — il ne peut plus être modifié une fois qu'un `HANDOVER` existe sur ce colis, pour empêcher un shipper de le rendre divisible a posteriori afin de contourner un litige de responsabilité partagée.

---

# 8. Split d'une expédition

```text
A possède 30 kg → 10 kg vers B, 20 kg vers C
```

```text
                    30 kg
                 SHIPPER A
                 /      \
              10 kg     20 kg
               ↓          ↓
           SHIPPER B   SHIPPER C
```

Le système crée deux legs indépendants avec un `parent_leg_id` commun, permettant de reconstruire l'arbre de split pour l'affichage de la chaîne de garde (§36).

---

# 9. Merge

```text
SHIPPER A (10 kg) ─┐
                    → SHIPPER C (18 kg)
SHIPPER B (8 kg)  ─┘
```

C possède 18 kg, mais chaque sous-lot conserve son `origin_leg_id` et son historique propre.

---

# 10. Ne jamais fusionner l'historique

```text
PACKAGE A — origin = Shipper A
PACKAGE B — origin = Shipper B
```

même transportés ensemble par C ensuite. Cela permet de répondre à : *Qui avait ce colis ? Quand ? Où ? Pendant combien de temps ? Qui a accepté le transfert ? Qui était responsable à quel instant ?* — la même exigence de traçabilité que celle qu'exposent les grands réseaux de fret dans leurs API de tracking public.

---

# 11. Modèle de chaîne de garde

```text
SHIPMENT
   ├── PACKAGE A → Custody A → Custody B → Custody C
   ├── PACKAGE B → Custody A → Custody D
   └── PACKAGE C → Custody A
```

---

# 12. Entité Shipment

```text
shipments
  id
  tracking_number         (CLX-YYYY-NNNNNN, unique, public)
  internal_id              (UUID, interne uniquement)
  client_id
  origin / destination
  status                   (voir §81 — machine à états globale)
  total_weight
  total_packages
  declared_value
  currency
  max_hop_count             ← nouveau, défaut 5 (voir §1)
  created_at / updated_at
```

---

# 13. Entité Package

```text
shipment_packages
  id
  shipment_id
  tracking_code            (CLX-YYYY-NNNNNN-NN)
  package_number
  weight
  declared_value
  description
  is_divisible              (verrouillé après premier handover)
  package_fingerprint       ← nouveau (voir §2.4)
  status
  current_custodian_id
  current_leg_id
  created_at / updated_at
```

---

# 14. Entité Trip

```text
trips
  id
  shipper_id
  origin / destination
  origin_location / destination_location   (geo)
  departure_at / estimated_arrival_at
  capacity_kg / reserved_kg / available_kg
  price_per_kg
  flight_number
  status
  created_at / updated_at
```

Structure inchangée par rapport au système actuel — elle est déjà correcte et s'étend directement.

---

# 15. Entité Booking

```text
bookings
  id
  shipment_id
  package_id                (nullable si booking porte sur poids brut)
  client_id / shipper_id / trip_id
  requested_weight / allocated_weight
  price_per_kg / total_price
  status / payment_status
  idempotency_key            ← nouveau (voir §29bis)
  created_at / updated_at
```

---

# 16. Entité ShipmentLeg

```text
shipment_legs
  id
  shipment_id
  trip_id / shipper_id
  from_location / to_location
  planned_departure / planned_arrival
  actual_departure / actual_arrival
  allocated_weight
  status
  sequence_number
  parent_leg_id              ← nouveau, pour reconstruire les arbres de split/merge
  created_at / updated_at
```

---

# 17. Entité Custody Transfer

```text
custody_transfers
  id
  shipment_id
  from_user_id / to_user_id
  from_leg_id / to_leg_id
  transfer_type              (FULL | PARTIAL | PACKAGE | MERGE | SPLIT)
  total_weight
  status
  requested_at / accepted_at / completed_at
  latitude / longitude
  verification_method
  qr_token_id / otp_id
  chain_hash                  ← nouveau (voir §3)
  signature_from / signature_to ← nouveau
  notes
  created_at
```

---

# 18. Entité Shipment Event

```text
shipment_events
  id
  shipment_id / package_id (nullable) / leg_id (nullable)
  event_type
  actor_id
  latitude / longitude / accuracy
  created_at
  metadata
  proof_id
  expected_by                ← nouveau : horodatage de l'attente SLA du prochain événement (voir §21bis)
```

---

# 19. Événements standards

```text
ORDER_CREATED
BOOKING_CREATED / BOOKING_CONFIRMED
HANDOVER_READY
COLLECTED
DEPARTED_ORIGIN
ARRIVED_ORIGIN_AIRPORT
SECURITY_CHECK
CUSTOMS_SUBMITTED / CUSTOMS_HOLD / CUSTOMS_CLEARED
IN_TRANSIT
TRANSFER_REQUESTED / TRANSFER_ACCEPTED / TRANSFER_COMPLETED
ARRIVED_DESTINATION_AIRPORT
DESTINATION_CUSTOMS_HOLD / DESTINATION_CUSTOMS_CLEARED
READY_FOR_DELIVERY
OUT_FOR_DELIVERY
DELIVERY_ATTEMPTED / DELIVERY_FAILED
DELIVERED
```

Cette liste reprend et complète la logique en jalons vs. exceptions employée par les réseaux de référence (DHL distingue explicitement les étapes de progression des événements d'exception dans son modèle de tracking).

---

# 20. Exceptions

Namespace distinct, jamais mélangé aux jalons de progression :

```text
SHIPPER_DELAY / MISSED_FLIGHT / FLIGHT_CANCELLED
NETWORK_DELAY / CUSTOMS_HOLD
DOCUMENT_MISSING
ADDRESS_INVALID / RECIPIENT_UNAVAILABLE
PACKAGE_DAMAGED / PACKAGE_LOST
SECURITY_ISSUE
TRANSFER_FAILED / TRANSFER_DECLINED
DELIVERY_FAILED
```

---

# 21. Pourquoi les exceptions sont indispensables

Un colis `IN_TRANSIT` pendant 24h sans nouvel événement n'est pas nécessairement bloqué. CargoLink doit distinguer l'absence d'information de l'incident confirmé — c'est la même logique que celle exposée par les grands réseaux, où l'absence d'événement ne signifie pas l'arrêt de la progression, alors qu'un événement d'exception signale explicitement une perturbation réelle.

```text
🟢 En transit — Dernière mise à jour : il y a 4 h
```

et non :

```text
🔴 Bloqué
```

sans preuve d'incident réel.

## 21bis. SLA proactif — l'ajout manquant dans l'original

L'original se contente de dire qu'il ne faut pas afficher "bloqué" à tort, mais ne définit aucun mécanisme pour **détecter** un vrai retard. Ceci est la principale lacune corrigée ici, sur le modèle des moteurs de tracking exception-based utilisés par les réseaux matures :

Chaque événement porte un `expected_by` calculé à sa création (ex: `COLLECTED` → `expected_by = now + 4h` pour `DEPARTED_ORIGIN`). Un job planifié scanne les shipments actifs :

```text
SI now > expected_by ET aucun événement suivant reçu
ALORS créer automatiquement
   shipment_exceptions { type: SLA_BREACH, severity: WARNING }
```

Ce n'est **jamais** affiché comme un échec au Client — cela déclenche une vérification interne (notification Shipper : "Confirmez votre statut", puis escalade Admin si pas de réponse sous un second délai). C'est ce mécanisme qui transforme "on espère que ça avance" en un système qui détecte activement la dérive.
---

# 22. Workflow de transfert entre Shippers — vue d'ensemble

```text
A possède 10 kg, veut en transférer 6 kg à B
```

```text
1. A sélectionne les colis/poids à transférer
2. A recherche un Shipper compatible (destination, capacité, date)
3. B reçoit une demande de transfert
4. B accepte ou refuse
5. Génération QR + OTP + fenêtre de validité
6. Remise physique
7. Double confirmation (A confirme la remise, B confirme la réception)
8. Transaction serveur atomique : bascule de custody
9. chain_hash mis à jour, événement TRANSFER_COMPLETED créé
```

---

# 23. Sélection du mode de transfert

```text
Que souhaitez-vous transférer ?

○ Tout
○ Une partie (poids)
○ Certains colis (recommandé)
```

---

# 24. Recherche du nouveau Shipper

```text
Shippers disponibles — Paris → Madrid

Karim ⭐ 4.9 (score de confiance 92)
Capacité disponible : 8 kg
Prix : 700 DZD/kg
Départ : 22 septembre

[ Demander le transfert ]
```

Le score affiché n'est plus une simple moyenne d'étoiles (voir §24bis).

## 24bis. Score de confiance pondéré par enjeu — nouveau

L'original ne proposait qu'une note `⭐ 4.9` classique, qui pose un problème connu des marketplaces P2P à forte valeur : une note moyenne ne distingue pas un shipper qui a fait 200 livraisons de sacs de vêtements d'un shipper qui a fait 5 livraisons d'électronique de valeur. Sur le modèle des systèmes de confiance à enjeu utilisés par les plateformes P2P matures (location de véhicules, biens de valeur), CargoLink calcule un **Trust Score** distinct de la note :

```text
trust_score = f(
  nombre de handovers complétés sans litige,
  valeur cumulée transportée sans incident,
  taux de respect des délais déclarés,
  ancienneté du compte,
  vérification KYC (niveau),
  taux de litiges perdus en tant que défendeur
)
```

Ce score conditionne : le montant maximum de `declared_value` qu'un shipper peut accepter sans validation Admin, et l'éligibilité à transporter des colis marqués `HIGH_VALUE` ou `FRAGILE`.

---

# 25. Demande de transfert

```text
🔄 Demande de transfert

Ahmed veut vous remettre : 6 kg
Expédition : CLX-2026-000184
Origine : Alger — Destination : Madrid
Point de remise : Paris

[ Refuser ]  [ Accepter ]
```

---

# 26. Acceptation

```text
TRANSFER_ACCEPTED
```

génère `handover_id` + QR + OTP, avec une fenêtre de validité limitée (voir §31).

---

# 27. Remise inter-Shipper

```text
A                              B
Transfert 6 kg                Recevoir 6 kg
Code : 824391                 [ Scanner QR ]
QR ██████████                 ou entrer le code
[ Valider la remise ]         [ ______ ]
```

---

# 28. Double validation

```text
TRANSFER_COMPLETED
```

uniquement lorsque A **et** B confirment. Aucune des deux confirmations seules ne change l'état de custody.

---

# 29. Mise à jour de possession

```text
Avant : A = 10 kg, B = 0 kg
Après : A = 4 kg, B = 6 kg
```

Transaction serveur atomique — jamais deux écritures séparées.

## 29bis. Idempotence — l'ajout critique manquant

L'original impose une "transaction atomique" (§30, §93) mais ne traite jamais le cas du **retry réseau**. Sur un réseau P2P avec zones de faible connectivité (aéroports, douanes), un client qui soumet une confirmation de handover peut ne jamais recevoir la réponse serveur et retenter — sans mécanisme d'idempotence, cela peut déclencher un double débit de capacité ou une double bascule de custody.

Chaque appel `complete_transfer()`, `confirm_delivery()`, `create_booking()` porte un `idempotency_key` généré côté client (UUID v4, stocké localement avant l'appel). Le serveur :

```text
SI idempotency_key déjà traité
ALORS retourner le résultat déjà produit (pas de nouvelle écriture)
SINON traiter et enregistrer la clé
```

C'est le même principe que celui employé par les API de paiement pour garantir qu'un retry réseau ne débite jamais deux fois — appliqué ici à chaque opération qui modifie une garde ou un solde.

---

# 30. Interdiction des doubles dépenses de capacité

```text
A possède 10 kg
Transfert 1 : 6 kg → B
Transfert 2 : 6 kg → C   ← doit échouer
```

```text
available_custody = current_weight − pending_transfer_weight
```

calculé serveur, jamais côté client, jamais en confiance sur l'état local.

---

# 31. Verrouillage transactionnel

Toute opération critique (`transfer`, `handover`, `booking`, `payment`, `delivery`) passe par une transaction PostgreSQL / RPC — jamais une séquence de UPDATE indépendants depuis Flutter.

## 31bis. Chaîne de hash cryptographique — le cœur de l'amélioration sécurité

C'est l'ajout le plus structurant de cette réécriture. L'original prévoyait QR + OTP comme seule preuve d'un handover (§32), ce qui protège contre l'usurpation d'identité au moment T mais ne protège pas contre la **falsification a posteriori** de l'historique — un acteur avec accès à la base pourrait en théorie réécrire un événement passé sans que rien ne le révèle.

Chaque `CustodyTransfer` calcule :

```text
chain_hash = SHA256(
  previous_chain_hash_for_this_package
  + from_user_id + to_user_id
  + package_ids + weight
  + timestamp_serveur
  + gps
)
```

et est signé par les deux clés privées (A et B) générées à l'inscription (Ed25519, stockées dans le keystore sécurisé de l'appareil — jamais transmises au serveur). Le serveur vérifie les deux signatures avant de committer.

**Ce que ça change concrètement pour les litiges (§85)** : un audit peut recalculer indépendamment la chaîne de hash de n'importe quel package et détecter immédiatement toute incohérence, sans avoir à faire confiance à l'intégrité de la base de données au moment de l'audit. C'est le principe d'un registre append-only vérifiable, appliqué à la chaîne de garde plutôt qu'à une monnaie.

---

# 32. QR de transfert

Le QR représente un `TRANSFER_TOKEN`, jamais directement un `shipment_id`. Il doit être unique, single-use, expirable (fenêtre de 15 minutes par défaut), signé par le serveur.

---

# 33. OTP

```text
QR scan → serveur demande OTP → OTP correct → handover validé
```

Le QR seul ne suffit jamais pour une opération critique (transfert, livraison) : il prouve la présence physique, l'OTP prouve le consentement actif de la personne, pas seulement de l'appareil.

---

# 34. Transfert sans réseau — protocole précisé

L'original se limitait à "préparer localement, signer localement, synchroniser plus tard" sans préciser *comment* signer de façon fiable. Voici le protocole complet qui comble ce vide :

```text
1. A et B sont hors-ligne (aéroport, zone blanche)
2. A génère un HANDOVER_DRAFT local avec chain_hash calculé
   à partir du dernier chain_hash connu localement pour ce package
3. A signe le draft avec sa clé privée
4. B scanne le QR (qui contient le draft signé, pas juste un ID)
5. B vérifie la signature de A localement (clé publique de A
   déjà en cache depuis l'appariement initial)
6. B signe à son tour le draft
7. Le draft doublement signé est stocké dans une queue locale
   sur les DEUX appareils (redondance : si un appareil perd
   les données avant sync, l'autre a la preuve)
8. Statut affiché : PENDING_SYNC — jamais TRANSFER_COMPLETED
9. Dès reconnexion (l'un ou l'autre appareil), sync vers le serveur
10. Le serveur vérifie les deux signatures et la continuité du
    chain_hash avant de committer définitivement
11. SI le chain_hash local ne correspond pas au dernier chain_hash
    serveur connu (ex: le colis a été transféré ailleurs entre
    temps par erreur ou fraude) → conflit soumis à Admin,
    jamais résolu automatiquement en faveur du premier arrivé
```

Ce protocole garantit qu'aucune des deux parties ne peut prétendre unilatéralement qu'un transfert a eu lieu, et que la preuve survit à la perte d'un seul appareil.

---

# 35. Tracking par package

```text
Expédition — 30 kg
PKG-0001 — 10 kg — 🟢 Paris
PKG-0002 — 8 kg — 🟢 Madrid
PKG-0003 — 12 kg — 🟠 Douane
```

Indispensable pour le multi-Shipper et les transferts partiels — sans ce niveau de granularité, un client ne peut pas comprendre pourquoi "son colis" a trois statuts différents.

---

# 36. Vue globale Client

```text
📦 CLX-2026-000184
Alger → Madrid
30 kg / 3 colis

10 kg  🟢 En transit
8 kg   🟠 Douane
12 kg  🟢 Paris

Progression globale
████████░░░░ 67 %
```

---

# 37. Vue Chain of Custody

```text
Client
  │ 30 kg
  ▼
Ahmed (Alger)
  ├── 10 kg → Karim (Paris)
  └── 20 kg → Ahmed → Madrid
```

Chaque nœud affiche, au tap : durée de garde, preuve de handover, statut de vérification de la chaîne de hash.

---

# 38. Carte tracking

```text
📍 position actuelle du Shipper
📦 colis concernés
✈️ aéroports
📍 points de transfert / destination
```

Jamais l'adresse personnelle exacte du Shipper exposée au Client.

---

# 39. Confidentialité GPS

```text
📍 À proximité de Paris     (Client voit ceci)
48.856614, 2.352221         (donnée de preuve interne uniquement)
```

---

# 40. Background tracking

```text
Application ouverte / minimisée / écran verrouillé / background → ✓
```

dans les limites imposées par Android (foreground service + notification persistante requise dès Android 12+) et iOS (Background App Refresh, significant-change location service).

```text
Native Background Location → Location Service → Local Queue
→ ObjectBox → Batch Sync → Supabase → Realtime
```

---

# 41. Adaptive GPS

```text
Normal              30–120 s
Vitesse élevée       fréquence ↑
Approche aéroport    fréquence ↑
Arrêt                fréquence ↓
Réseau indisponible  local queue (ObjectBox), purge après sync confirmée
```

---

# 42. Géofencing

```text
Aéroport / Douane / Point relais / Zone de livraison
```

Le geofence **suggère** une transition d'état, il ne la valide jamais seul :

```text
GPS → Suggestion → Utilisateur confirme → Event
```

---

# 43. Livraison

```text
READY_FOR_DELIVERY → OUT_FOR_DELIVERY
```

```text
🚚 Livraison en cours
Créneau : 15:00 – 17:00
[ Voir la carte ]
```

---

# 44. Tentative de livraison

```text
DELIVERY_ATTEMPTED → DELIVERY_FAILED
```

Raison : `RECIPIENT_UNAVAILABLE / WRONG_ADDRESS / REFUSED / OTHER`

```text
[ Reprogrammer ]  [ Nouveau point de remise ]
[ Point relais ]  [ Contacter le Shipper ]
```

---

# 45. Preuve de livraison

```text
Proof of Delivery
  shipment / package / recipient
  timestamp / location
  verification (OTP)
  signature (optionnelle)
  photo (optionnelle)
  shipper
  chain_hash final du package    ← nouveau, clôt la chaîne de garde
```
---

# 46. Livraison sans signature

```text
PHOTO_POD  ou  OTP_POD
```

Par défaut CargoLink garde `QR + OTP`, plus adapté qu'une simple signature à un contexte P2P où le destinataire ne connaît pas physiquement le Shipper.

---

# 47. Douane

```text
CUSTOMS_SUBMITTED
CUSTOMS_PROCESSING
CUSTOMS_HOLD
CUSTOMS_DOCUMENT_REQUIRED
CUSTOMS_FEES_REQUIRED
CUSTOMS_CLEARED
CUSTOMS_REJECTED
```

Documents : facture, proforma, preuve d'achat, description, valeur, origine, documents réglementaires. Le rôle central de la facture commerciale et du document de transport dans le traitement douanier et le suivi est la norme dans le fret international — CargoLink applique le même principe à l'échelle du colis individuel plutôt que du conteneur.

---

# 48. Responsabilité douanière

```text
Qui est responsable ?  → Client / Shipper / Destinataire (déclaré explicitement à la création)
Qui paie ?              → Droits / Taxes / Frais de douane / Stockage / Retour
```

Jamais implicite : le Client choisit ce paramètre lors de la création de l'expédition, et il est affiché sur chaque écran de suivi douanier concerné.

---

# 49. Colis saisi par la douane

```text
CUSTOMS_HOLD → (éventuellement) CUSTOMS_SEIZED
```

```text
1. Geler le payout concerné
2. Ouvrir un shipment_event de type EXCEPTION
3. Notifier Client + Shipper
4. Créer une alerte Admin priorité haute
5. Ouvrir automatiquement un dossier de litige (catégorie customs_seizure)
```

---

# 50. Disputes — intégration transverse

Le système possède déjà `open → investigating → resolved / rejected` avec des catégories (`fraud`, `customs_seizure`, `damage`). La V2 rend ce mécanisme accessible **à chaque niveau de granularité**, pas uniquement en backend :

```text
Sur une expédition   → [ ⚠ Signaler un problème ]
Sur un colis          → [ ⚠ Signaler ce colis ]
Sur un transfert       → [ ⚠ Signaler le transfert ]
```

---

# 51. Types de litiges

```text
LOST / DAMAGED / MISSING_PACKAGE / WRONG_PACKAGE
WRONG_WEIGHT / CONTENT_MISMATCH
UNAUTHORIZED_TRANSFER
SHIPPER_FRAUD / CLIENT_FRAUD
CUSTOMS_HOLD / CUSTOMS_SEIZURE
DELIVERY_FAILED / DELIVERED_NOT_RECEIVED
WRONG_RECIPIENT / WRONG_DESTINATION
PAYMENT_PROBLEM / REFUND_PROBLEM
DELAY / OTHER
```

---

# 52. Ouverture d'un litige

```text
Quel problème avez-vous ?
○ Colis perdu   ○ Colis endommagé   ○ Colis incomplet
○ Mauvais destinataire   ○ Problème douanier
○ Livraison non reçue   ○ Problème de paiement   ○ Autre

Expliquez le problème
[ ____________________ ]

Photos / documents
[ + Ajouter ]

[ Ouvrir le litige ]
```

---

# 53. Evidence Pack

```text
tracking history / custody history / booking / payment
photos / QR scans / OTP validation / GPS events
messages / proof of delivery / documents
chain_hash verification report      ← nouveau
```

## 53bis. Rapport de vérification automatique — nouveau

L'Admin ne doit jamais reconstruire l'histoire manuellement. À l'ouverture d'un litige, le système génère automatiquement un rapport qui recalcule la chaîne de hash de chaque package concerné et signale toute rupture :

```text
Package PKG-0001 — Intégrité de la chaîne : ✓ VÉRIFIÉE (6 handovers, 0 rupture)
Package PKG-0002 — Intégrité de la chaîne : ⚠ RUPTURE détectée entre
                    Handover #3 (Ahmed → Karim) et Handover #4 (Karim → Sami)
                    → chain_hash attendu ≠ chain_hash reçu
                    → Priorité d'investigation : Handover #4
```

Ceci transforme une investigation qui prenait auparavant des heures de lecture manuelle de logs en un point de départ immédiat et objectif pour l'Admin.

---

# 54. Exemple de litige

```text
Client : "Le colis était intact à Alger mais arrivé endommagé à Madrid."
```

```text
PACKAGE PKG-0001
COLLECTED — Ahmed — Alger — ✓ Photo
TRANSFER — Ahmed → Karim — Paris — ✓ QR ✓ OTP ✓ GPS ✓ chain_hash valide
ARRIVED — Madrid
DELIVERED — Karim — ✓ OTP ✓ Photo
DISPUTE — Damage
```

L'Admin détermine, à partir des photos horodatées à chaque étape (collecte, transfert, livraison), l'intervalle de garde le plus probable de l'apparition du dommage.

---

# 55. Gel financier

```text
Litige critique ouvert → PAYOUT = FROZEN
```

---

# 56. Payout par étape

```text
Payment
 ├── Allocation A
 ├── Allocation B
 └── Allocation C

Shipper A → payout = pending
Shipper B → payout = pending
Shipper C → payout = pending
```

Libéré selon :

```text
handover confirmé + leg terminé + absence de litige sur cette allocation
```

## 56bis. Échec partiel — le trou comblé

L'original ne traite jamais ce cas, pourtant central en multi-shipper : *que se passe-t-il si Shipper B livre correctement sa portion, mais Shipper C perd la sienne ?* Sans règle explicite, deux comportements incorrects sont possibles : geler tout le paiement (pénalise B injustement) ou tout libérer (paie C pour un colis perdu).

**Règle CargoLink V2 : le payout est toujours scindé au niveau de l'allocation, jamais au niveau du shipment.**

```text
Shipment CLX-2026-000184 — DISPUTED (partiel)
  Allocation A (12 kg, livré) → payout = RELEASED
  Allocation B (10 kg, livré) → payout = RELEASED
  Allocation C (8 kg, perdu)  → payout = FROZEN, dispute ouverte
```

Chaque `payment_allocation` a son propre cycle de vie indépendant des autres allocations du même shipment. C'est la conséquence directe du modèle de custody par package (§10) : puisque l'historique n'est jamais fusionné entre packages, le paiement ne doit pas l'être non plus.

---

# 57. Commission CargoLink

```text
Booking
 ├── transport_price
 ├── platform_fee        (5 % — inchangé)
 ├── insurance_fee (optionnel)
 ├── customs_fee (optionnel)
 └── payout
```

---

# 58. Payout multi-Shipper — exemple chiffré

```text
30 kg — Client paie 30 000 DZD

Shipper A — 10 kg → 8 000 DZD
Shipper B — 8 kg  → 6 400 DZD
Shipper C — 12 kg → 9 600 DZD
```

`platform_fee` prélevée selon les règles commerciales, par allocation (voir §56bis) — jamais sur le total avant répartition, pour que le gel d'une allocation ne bloque pas le calcul des deux autres.

---

# 59. Annulation

```text
Avant confirmation              → ANNULABLE
Après confirmation, avant collecte → ANNULABLE (selon conditions)
Après collecte                   → RESTRICTED
Après départ                     → ADMIN / DISPUTE
Après livraison                  → DISPUTE ONLY
```

---

# 60. Remboursement

Toujours lié à : `booking + payment + leg + payout + dispute` — jamais un simple `payment.status = refunded` déconnecté du reste du graphe transactionnel.

---

# 61. Incident moteur

```text
shipment_exceptions
  id / shipment_id / package_id / leg_id
  type / severity
  description
  reported_by / reported_at
  location
  status
  resolved_at / resolved_by / resolution
  auto_generated              ← nouveau : distingue une exception créée par SLA (§21bis) d'une déclarée par un humain
```

---

# 62. Niveau de gravité

```text
INFO       — ex: retard mineur, aucune action requise
WARNING    — ex: retard de 2h, surveillance automatique
CRITICAL   — ex: colis perdu, gel financier immédiat
```

---

# 63. Centre opérationnel Admin

```text
OPERATIONS
Expéditions actives       182
En transit                 74
En douane                   9
Transferts actifs          12
Livraisons en cours        21
Incidents                   7
Litiges                     4
Ruptures de chaîne détectées 0   ← nouveau (voir §53bis)
```

---

# 64. Live Operations Map

Filtres : `Tous / En transit / Aéroport / Douane / Exception / Livraison / Litige`

---

# 65. Recherche opérationnelle

```text
tracking number / package tracking / booking ID / user
shipper / flight / trip / dispute / chain_hash        ← nouveau
```

Rechercher directement par `chain_hash` permet à l'Admin de vérifier instantanément si un hash cité par un utilisateur (capture d'écran, litige externe) existe réellement dans la chaîne.

---

# 66. Audit complet

```text
audit_logs
  WHO / WHAT / WHEN / WHERE / BEFORE / AFTER / DEVICE / IP
```

```text
Ahmed — HANDOVER_COMPLETED — PKG-0001 — 8 kg — Alger Airport
19/09/2026 18:43 — QR + OTP — chain_hash: 7f3a9c...
```

---

# 67. Notifications

**Client :** réservation envoyée/confirmée/refusée, point de remise confirmé, colis récupéré, voyage commencé, arrivée aéroport, en transit, transfert demandé/effectué, douane, exception, livraison en cours, tentative de livraison, colis livré, litige ouvert/mis à jour/résolu.

**Shipper :** nouvelle réservation, réservation annulée, transfert demandé/accepté/refusé, nouveau colis à récupérer, destination modifiée, litige ouvert, payout disponible, **alerte SLA proche de l'échéance** ← nouveau (conséquence de §21bis).

---

# 68. Tracking public

```text
tracking.cargolink / CLX-2026-000184
```

sans connexion, mais limité à : statut, événements généraux, ville, date. Jamais : nom complet du Shipper, position GPS précise, téléphone, adresse privée.

---

# 69. Numéros de tracking

```text
tracking_number : CLX-2026-000184     (public, lisible)
internal_id     : UUID                (interne, jamais exposé)
```

---

# 70. Package tracking

```text
CLX-2026-000184-01
CLX-2026-000184-02
CLX-2026-000184-03
```
---

# 71. Scan QR universel

```text
Le même scanner reconnaît : COLLECTION / TRANSFER / DELIVERY / RETURN
QR → Token → Action → Authorization → Confirmation
```

Le serveur détermine le contexte à partir du token, jamais le client — un QR ne doit jamais encoder l'action elle-même, seulement une référence opaque, pour empêcher toute falsification de contexte côté client.

---

# 72. Retour

```text
RETURN_REQUESTED → RETURN_ACCEPTED → RETURN_IN_TRANSIT
→ RETURN_ARRIVED → RETURN_DELIVERED
```

Un retour crée de nouveaux legs avec `parent_leg_id` pointant vers le leg d'origine — jamais une réutilisation des legs existants, pour garder la timeline linéaire et lisible.

---

# 73. Redirection

```text
Client demande : Changer destination
```

Après départ → `REQUIRES_REVIEW`. Le système recalcule : nouvelle route, nouveaux Shippers, nouveau prix, nouvelle douane. Toute redirection après collecte nécessite une confirmation explicite du Shipper actuel avant recalcul (il n'est pas obligé d'accepter le nouveau trajet).

---

# 74. Route dynamique

```text
Shipper A annule pendant le voyage → A = CANCELLED
CargoLink recherche B / C / D compatibles (position, destination, capacité, date)
```

---

# 75. Rebooking automatique

```text
Exception → Recherche Shippers → Matching → Propositions
→ Client/Admin validation → New Leg → Handover
```

Le matching priorise les shippers avec `trust_score` élevé (§24bis) proportionnellement à la `declared_value` du colis à réacheminer — un colis de forte valeur en situation d'urgence ne doit pas être proposé au premier shipper disponible sans filtre de confiance.

---

# 76. Aucun événement ne doit écraser l'historique

```text
Interdit : UPDATE event
Correct  : NEW_CORRECTION_EVENT référençant l'event corrigé
```

Les événements sont append-only sans exception — y compris pour corriger une erreur de saisie, qui doit produire un nouvel événement plutôt qu'une modification silencieuse (cohérent avec le principe de chaîne vérifiable du §31bis : modifier un événement passé casserait le chain_hash).

---

# 77. Source de vérité

```text
Shipment          → état courant agrégé
ShipmentEvent      → vérité historique
ShipmentLeg         → responsabilité de transport
CustodyTransfer      → historique de possession, vérifiable cryptographiquement
TrackingPoint         → preuve de localisation physique
Proof                  → preuve (photo, signature, OTP)
Dispute                  → résolution de conflit
```

---

# 78. Machine à états globale — reformalisée

L'original présentait un diagramme linéaire simple qui ne gérait pas correctement les branches parallèles (multi-leg) ni les états terminaux d'échec en dehors du chemin heureux. Voici la version formalisée par entité, avec table de transitions explicite — le principe étant qu'**aucune transition ne doit être possible en dehors de cette table**, appliquée au niveau du RPC serveur, jamais laissée à la logique client.

```text
CREATED
  → BOOKING_PENDING
BOOKING_PENDING
  → BOOKING_CONFIRMED | CANCELLED
BOOKING_CONFIRMED
  → HANDOVER_PENDING | CANCELLED
HANDOVER_PENDING
  → COLLECTED | CANCELLED (avant collecte uniquement)
COLLECTED
  → DEPARTED | EXCEPTION
DEPARTED
  → ORIGIN_AIRPORT | EXCEPTION
ORIGIN_AIRPORT
  → IN_TRANSIT | EXCEPTION
IN_TRANSIT
  → CUSTOMS | IN_TRANSIT (leg suivant, via transfert) | EXCEPTION
CUSTOMS
  → CUSTOMS_HOLD | DESTINATION_AIRPORT
CUSTOMS_HOLD
  → CUSTOMS_CLEARED | DISPUTED (customs_seizure)
CUSTOMS_CLEARED
  → DESTINATION_AIRPORT
DESTINATION_AIRPORT
  → READY_FOR_DELIVERY
READY_FOR_DELIVERY
  → OUT_FOR_DELIVERY
OUT_FOR_DELIVERY
  → DELIVERY_ATTEMPTED | DELIVERED
DELIVERY_ATTEMPTED
  → OUT_FOR_DELIVERY (retry) | DELIVERY_FAILED
DELIVERY_FAILED
  → OUT_FOR_DELIVERY (reprogrammé) | RETURNING | DISPUTED

États orthogonaux (accessibles depuis tout état non-terminal) :
  EXCEPTION → retour à l'état précédent une fois résolu, ou DISPUTED
  DISPUTED  → RESOLVED (retour état antérieur) | terminal via CLAIM
  CANCELLED → terminal
  LOST      → terminal (via DISPUTED uniquement, jamais direct)
```

Point clé absent de l'original : **`LOST` et `CANCELLED` ne sont jamais des transitions directes depuis un état de progression.** Elles passent obligatoirement par `EXCEPTION` ou `DISPUTED`, pour garantir qu'aucun acteur ne peut déclarer unilatéralement un colis perdu sans processus de vérification.

---

# 79. Multi-Leg State — état par leg

```text
LEG 1 — Alger → Paris — ✓ COMPLETED
LEG 2 — Paris → Madrid — 🟢 IN_TRANSIT
LEG 3 — Madrid → Destination — ○ PENDING
```

Le Shipment global reste `IN_TRANSIT` tant qu'au moins un leg actif existe — mais voir §81 pour la nuance introduite par le multi-package.

---

# 80. Shipment global vs Package — agrégation correcte

```text
Shipment 30 kg
  Package 1 — 10 kg → Delivered
  Package 2 — 8 kg  → Customs Hold
  Package 3 — 12 kg → In Transit
```

Le Shipment global affiche `PARTIALLY_DELIVERED`, jamais `DELIVERED` tant qu'un seul package n'a pas atteint un état terminal positif.

**Règle d'agrégation formalisée** (absente de l'original, qui donnait l'exemple sans la règle générale) :

```text
Shipment.status = DELIVERED           SI tous les packages = DELIVERED
Shipment.status = PARTIALLY_DELIVERED SI au moins un DELIVERED ET au moins un non-terminal ou non-délivré
Shipment.status = DISPUTED            SI au moins un package DISPUTED (prioritaire sur PARTIALLY_DELIVERED)
Shipment.status = <état du package le moins avancé>  sinon
```

---

# 81. Statuts globaux

```text
CREATED
PARTIALLY_BOOKED / FULLY_BOOKED
PARTIALLY_COLLECTED / COLLECTED
PARTIALLY_IN_TRANSIT / IN_TRANSIT
PARTIALLY_DELIVERED / DELIVERED
EXCEPTION / DISPUTED / CANCELLED / RETURNED
```

---

# 82. Exemple réel de scénario

```text
Client : 30 kg, Alger → Madrid
1. Shipper A collecte 30 kg à Alger
2. A arrive Paris, transmet 10 kg → B, 20 kg → C
3. B : Paris → Madrid (10 kg) ; C : Paris → Madrid (20 kg)
4. B livre ses 10 kg ; C livre ses 20 kg
```

```text
PACKAGE 1 — ✓ Delivered by B
PACKAGE 2 — ✓ Delivered by C
Shipment — ✓ DELIVERED
```

---

# 83. Exemple avec incident

Même scénario, mais B perd son colis de 10 kg.

```text
PACKAGE 1 — LOST (via EXCEPTION → DISPUTED, jamais direct — voir §78)
PACKAGE 2 — 20 kg → continue normalement
Shipment — PARTIALLY_DELIVERED + DISPUTED
```

Le Client ouvre un litige sur PACKAGE 1 sans bloquer PACKAGE 2 — et le payout de l'allocation C reste `RELEASED` indépendamment (§56bis).

---

# 84. Dispute granulaire

```text
dispute.entity_type = package
dispute.entity_id   = PKG-0001
```

Un litige peut porter sur : Shipment, Booking, Leg, Package, Transfer, Payment, Delivery.

---

# 85. Résolution Admin

```text
DISPUTE #D-00042 — Package Lost — PKG-0001 — Valeur 250 €

Chain of custody
Client → Ahmed → Karim → UNKNOWN

Dernier événement : TRANSFER_COMPLETED — Paris — 14:42
Intégrité de la chaîne : ⚠ à vérifier (voir rapport §53bis)

Actions : Request evidence / Contact Shippers / Freeze payout
          Refund client / Compensate / Reject claim / Escalate
```

---

# 86. Claims / Réclamations

```text
Dispute  → conflit entre utilisateurs / plateforme
Claim    → demande formelle d'indemnisation
```

```text
Dispute → Investigation → Claim → Decision → Payout / Refund
```

---

# 87. Claim documents

```text
facture / preuve d'achat / photos / packing list
preuve de livraison / historique tracking / preuve de remise
documents douaniers
```

---

# 88. Sécurité financière

Pendant `DISPUTE / CUSTOMS_HOLD / LOST / DAMAGED`, le payout de l'allocation concernée (jamais du shipment entier — §56bis) peut être `FROZEN`.

---

# 89. Architecture Supabase cible

```text
users / shipper_profiles / trips / trip_capacity
shipments / shipment_packages / bookings / shipment_legs
custody_transfers / shipment_events / tracking_points
shipment_proofs / delivery_attempts
payments / payment_allocations / payouts
notifications / messages
disputes / claims / claim_documents
shipment_exceptions / audit_logs
device_keys                          ← nouveau (voir §31bis, stocke les clés publiques Ed25519)
```

---

# 90. Relations principales

```text
USER
 ├── SHIPPER_PROFILE
 └── TRIP
       └── BOOKING
             └── SHIPMENT
                   ├── PACKAGES
                   ├── LEGS
                   ├── EVENTS
                   ├── TRACKING
                   ├── TRANSFERS
                   ├── PROOFS
                   ├── DISPUTES
                   └── CLAIMS
```

---

# 91. RLS

```text
Client  → ses shipments, bookings, packages, events
Shipper → ses trips, bookings, legs, colis sous sa garde, tracking points
Admin   → global operations
```

Toutes les opérations critiques passent par RPC ou Edge Function — **jamais un UPDATE direct autorisé par RLS seul sur `shipment_packages.current_custodian_id` ou tout champ de solde**, même pour le propriétaire apparent de la ligne. RLS protège la lecture et les écritures non critiques ; les écritures critiques doivent être impossibles même avec une policy RLS mal configurée, parce qu'elles n'existent tout simplement pas en dehors des fonctions RPC `SECURITY DEFINER`.

---

# 92. Fonctions serveur critiques

```text
create_booking() / confirm_booking() / cancel_booking()
create_handover() / accept_handover() / confirm_handover()
start_trip() / confirm_airport_arrival()
create_transfer() / accept_transfer() / complete_transfer()
start_delivery() / confirm_delivery()
create_dispute() / freeze_payout() / resolve_dispute()
create_claim() / approve_claim() / refund_payment() / release_payout()
```

Chaque fonction ci-dessus accepte un `idempotency_key` (§29bis) et vérifie la signature cryptographique associée (§31bis) quand l'opération concerne une custody.

---

# 93. Transactions atomiques

```text
complete_transfer() dans une seule transaction :
 1. Vérifier A et B
 2. Vérifier quantité disponible (available_custody, §30)
 3. Vérifier package et is_divisible
 4. Vérifier token QR + OTP
 5. Vérifier idempotency_key
 6. Vérifier chain_hash et signatures (§31bis)
 7. Déplacer custody
 8. Créer event
 9. Créer proof
 10. Créer notification
 11. Créer audit
 12. Commit — ou ROLLBACK complet si une seule étape échoue
```
---

# 94. UX finale Client

```text
📦 Mon expédition — 30 kg — Alger → Madrid

🟢 10 kg — En transit
🟠 8 kg  — Douane
🟢 12 kg — Paris

[ Voir la carte ]
[ Voir la chaîne de garde ]
[ Contacter ]
[ Signaler un problème ]
```

---

# 95. UX finale Shipper

```text
🚚 Mon voyage — Alger → Madrid
Capacité : 20 kg — Réservé : 15 kg

COLIS
📦 8 kg — Ahmed → Moi
📦 7 kg — Mohamed → Moi

ACTIONS
[ Scanner un colis ]     [ Transférer un colis ]
[ Démarrer voyage ]      [ Arrivée aéroport ]
[ Livrer ]
```

---

# 96. UX transfert

```text
[ Transférer ]
Que souhaitez-vous transférer ?
○ Tout   ○ Une partie   ○ Certains colis
```

---

# 97. Transfert « Tout »

```text
Vous transférez : 20 kg / 3 colis
[ Rechercher Shipper ]
[ Continuer ]
```

---

# 98. Transfert « Une partie »

```text
Vous disposez de : 20 kg
Transférer : [ 8 kg ]
Reste : 12 kg
[ Continuer ]
```

---

# 99. Transfert « Certains colis » — mode recommandé

```text
☑ PKG-001 — 5 kg
☑ PKG-002 — 3 kg
☐ PKG-003 — 12 kg
Total : 8 kg
[ Continuer ]
```

Ce mode est mis en avant dans l'UI par défaut (voir §6) car il élimine toute ambiguïté de répartition entre colis, contrairement au transfert par poids brut.

---

# 100. Validation finale

```text
⚠ Confirmation

Vous allez remettre : 8 kg / 2 colis à Karim 📍 Paris

Après validation, Karim deviendra responsable de ces colis.
Cette action sera signée cryptographiquement et ne pourra
pas être annulée unilatéralement.

[ Annuler ]  [ Confirmer ]
```

La mention de la signature cryptographique dans le libellé de confirmation est volontaire : elle rend visible à l'utilisateur que l'action a une portée légale/probatoire, pas seulement un changement de statut dans une app.

---

# 101. Principe de responsabilité

```text
CURRENT_CUSTODIAN
```

toujours explicite (`PKG-001.current_custodian = Karim`), mais l'historique complet reste consultable (`Client → Ahmed → Karim`).

---

# 102. Période de garde

```text
custody_period
  custodian / start_at / end_at / location
```

```text
Ahmed : 19/09 18:43 → 22/09 09:10
Karim  : 22/09 09:10 → 23/09 16:30
```

---

# 103. Responsabilité par période

```text
Damage reported : 23/09 15:20
→ recherche current custody à cet instant → responsible custodian = Karim
```

Fonctionnalité clé pour trancher objectivement les litiges de responsabilité, combinée au rapport de vérification de chaîne (§53bis) pour confirmer que la période elle-même n'a pas été falsifiée.

---

# 104. Sécurité contre les faux événements

Un Shipper ne peut jamais créer arbitrairement `DELIVERED` ou `TRANSFER_COMPLETED`. Toute transition critique nécessite : `authorized actor + valid state (§78) + QR/OTP + timestamp serveur + location + signature (§31bis) + transaction serveur (§93)`.

---

# 105. Nature des preuves — hiérarchie

```text
GPS       → evidence de position
QR        → evidence d'identité / action
OTP       → confirmation humaine active
Photo     → evidence visuelle
Signature → evidence de livraison
chain_hash → evidence d'intégrité de l'historique complet   ← nouveau
```

L'ensemble forme l'**Evidence Pack** (§53) — aucune preuve seule n'est jamais suffisante ; c'est la combinaison qui rend un événement opposable en cas de litige.

---

# 106. Privacy

```text
Client  ne reçoit jamais le GPS exact du Shipper 24/7 → position logistique utile uniquement (§39)
Shipper voit le point de remise / destination, pas l'adresse privée du Client avant nécessité opérationnelle
```

---

# 107. Performance

```text
Tracking → batch upload
Realtime → events uniquement (jamais chaque point GPS brut)
GPS      → throttled (§41)
Images   → compression + resizing avant Storage
Database → indexes + pagination + RLS
```

---

# 108. Index PostgreSQL

```text
shipments(tracking_number)
shipments(client_id, status)
trips(shipper_id, status)
trips(origin, destination, departure_at)
bookings(shipper_id, status)
bookings(client_id, status)
shipment_packages(shipment_id)
shipment_packages(current_custodian_id)
shipment_events(shipment_id, created_at)
shipment_events(package_id, created_at)
shipment_legs(shipment_id, sequence_number)
custody_transfers(shipment_id, created_at)
custody_transfers(chain_hash)              ← nouveau, pour la recherche §65
tracking_points(shipment_id, created_at)
tracking_points(shipper_id, created_at)
disputes(status, created_at)
payment_allocations(shipment_id, payout_status)   ← nouveau (voir §56bis)
```

---

# 109. Pagination

Conserver la pagination actuelle (20 éléments/page). Événements : `latest first`. Timeline : `oldest → newest`.

---

# 110. Realtime

Supabase Realtime pour : booking status, shipment events, handover status, transfer status, disputes, messages. GPS (`tracking_points`) avec stratégie de throttling — jamais un flux realtime brut par défaut sur tous les points.

---

# 111. Push

FCM/APNs sur événement critique uniquement, jamais chaque point GPS :

```text
✓ Colis récupéré   ✓ Transfert effectué   ✓ Arrivée aéroport
⚠ Douane            ⚠ Exception            ✓ Livré
⚠ Alerte SLA         (nouveau, voir §21bis)
```

---

# 112. Expédition idéale — schéma complet

```text
CLIENT → SHIPPER A (30 kg) → PARIS
                                ├── 10 kg → SHIPPER B → MADRID ─┐
                                └── 20 kg → SHIPPER C → MADRID ─┴─→ DESTINATAIRE
```

Chaque flèche porte : QR, OTP, GPS, timestamp serveur, actor, event, proof, **chain_hash et double signature**.

---

# 113. Architecture métier finale

```text
                         SHIPMENT
                  ┌─────────┴─────────┐
               PACKAGES             BOOKINGS
                  │                   │
             CUSTODY                  TRIPS
                  └───────┬───────────┘
                     SHIPMENT LEGS
                 ┌────────┴────────┐
            TRACKING EVENTS    TRANSFERS
                 └────────┬────────┘
                       PROOFS
                 ┌────────┴────────┐
              DELIVERY          DISPUTE
                                   │
                                  CLAIM
                                   │
                                PAYOUT (par allocation, §56bis)
```

---

# 114. Règle d'or CargoLink

Une expédition n'est jamais simplement `status = shipped`. C'est :

```text
WHO + WHAT + WHERE + WHEN + UNDER WHOSE CUSTODY + PROOF
+ VÉRIFIABLE INDÉPENDAMMENT (chain_hash)
```

à chaque étape.

---

# 115. Résultat final

```text
                 CARGOLINK
       ┌─────────────┼─────────────┐
   MARKETPLACE    TRACKING      SECURITY
       │             │             ├── KYC
       │             │             ├── QR + OTP
       │             │             ├── GPS
       │             │             ├── Trust Score pondéré (§24bis)
       │             │             ├── Chaîne de hash vérifiable (§31bis)
       │             │             └── Audit
       │             ├── Events
       │             ├── Timeline
       │             ├── SLA proactif (§21bis)
       │             ├── Geofence
       │             └── Background
       ├── Client / Shipper / Trips / Capacity / Booking / Multi-Shipper
                     ▼
                 LOGISTICS
       ┌─────────────┼──────────────┐
    Handover      Customs       Delivery
       └─────────────┼──────────────┘
                  DISPUTES
                     │
                  CLAIMS
                     │
             PAYOUTS (par allocation)
```

---

# 116. Priorité d'implémentation

## Phase 1 — Core logistique
```text
1. Shipment  2. Package  3. Booking  4. Trip
5. ShipmentLeg  6. Custody  7. ShipmentEvent  8. State Machine (§78)
```

## Phase 2 — Sécurisation
```text
9. Handover  10. QR  11. OTP  12. Proof  13. Audit
14. Idempotence (§29bis)  15. Chaîne de hash (§31bis)
```

## Phase 3 — Tracking
```text
16. TrackingPoint  17. OpenStreetMap  18. Background GPS
19. Geofence  20. Offline Queue (§34)  21. Realtime  22. SLA engine (§21bis)
```

## Phase 4 — Réseau Shippers
```text
23. Partial Transfer  24. Full Transfer  25. Split  26. Merge
27. Multi-Leg  28. Rebooking  29. Rerouting  30. Trust Score (§24bis)
```

## Phase 5 — Exceptions
```text
31. Customs  32. Delay  33. Missed Flight  34. Failed Delivery
35. Lost  36. Damaged  37. Return
```

## Phase 6 — Protection
```text
38. Dispute  39. Claim  40. Evidence Pack  41. Rapport de vérification (§53bis)
42. Freeze Payout  43. Refund  44. Compensation  45. Admin Investigation
```

## Phase 7 — Business
```text
46. Commission  47. Payment Allocation (par unité, §56bis)  48. Payout
49. Ratings  50. Insurance  51. Dynamic Matching
```

**Note d'implémentation prioritaire** : contrairement à l'ordre naturel qui pousserait à traiter la sécurité (Phase 2) après le core logistique (Phase 1), l'idempotence (§29bis) et la state machine formalisée (§78) doivent être posées **dès la Phase 1** — ce sont des contraintes structurelles sur le schéma de données (clés, contraintes CHECK sur les transitions), pas des fonctionnalités additives. Les ajouter après coup impose une migration de données lourde sur `custody_transfers` et `shipment_events`.

---

# 117. Définition du produit final

CargoLink n'est plus :

> "Je réserve 5 kg chez un voyageur."

C'est :

> **Un réseau logistique collaboratif permettant à une marchandise d'être transportée par un ou plusieurs voyageurs, avec transfert total ou partiel de garde cryptographiquement vérifiable, suivi événementiel proactif, géolocalisation respectueuse de la vie privée, preuves opérationnelles combinées, gestion douanière explicite, exceptions détectées avant réclamation, litiges granulaires par colis, et règlement financier scindé par allocation.**

C'est cette architecture — combinant les standards de traçabilité du fret international (DHL, FedEx, UPS) et les mécanismes de confiance et d'intégrité des réseaux P2P décentralisés — qui fait passer CargoLink d'un simple marketplace de capacité bagage à un véritable réseau logistique multi-hop de confiance.
