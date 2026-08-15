# 🎠 CargoLink — Slider des Workflows par Rôle

> **Vue d'ensemble en « diapositives »** : chaque rôle et son workflow tiennent sur une slide. Ce document sert de source pour un composant Flutter de carrousel (`WorkflowSlider`) ou pour une présentation. Chaque slide a un **titre**, des **étapes numérotées** et des **règles clés**.

---

## Slide 1 — Vue d'ensemble

**CargoLink — Connecter voyageurs & clients (Algérie)**

- 🎯 –50 à –70 % vs DHL/FedEx
- 4 rôles : Client · Expéditeur · Admin · Super Admin
- Statut central : `pending → confirmed → shipped → delivered`
- Temps réel (Supabase Realtime), paiement Chargily/Stripe

---

## Slide 2 — Client : parcours

1. **Rechercher** une offre active (expéditeur vérifié).
2. **Réserver** : produit + photos + poids (0,1→50 kg).
3. **Payer** : Espèces / Virement / CCP / Chargily / Stripe.
4. **Suivre** en temps réel (timeline 8 étapes).
5. **Recevoir** : confirmer + noter l'expéditeur.

**Règles** : annulation seulement si `pending` ; poids réservé à la création ; litiges & chat disponibles.

---

## Slide 3 — Expéditeur : parcours

1. **KYC** : passeport + live selfie → vérification admin obligatoire.
2. **Publier** une offre `active` (origine, destination, prix ≥ 500 DZD/kg).
3. **Gérer les commandes** : confirmer → expédier → livrer.
4. **Suivre** les revenus (CA, commissions 5 %, historique).

**Règles** : pas de réservation si non vérifié ; refus = libération du poids + remboursement.

---

## Slide 4 — Admin : 4 onglets

| Onglet | Actions |
|---|---|
| **Expéditeurs** | Vérifier / rejeter / re-vérifier (KYC) |
| **Litiges** | Résoudre, rembourser, flagger |
| **Revenus** | Stats CA, transactions, commissions |
| **Inventaire** | Dépôts + colis (stored / dispatched / returned) |

**Règles** : RLS admin uniquement ; inventaire non visible des clients ; broadcasts ciblés.

---

## Slide 5 — Super Admin : contrôle total

1. **Stats globales** (utilisateurs, expéditeurs, revenus).
2. **Comptes** : changer rôles, activer/désactiver, supprimer définitivement.
3. **Vérification KYC** + litiges.
4. **Annonces** à toutes les audiences.
5. **Inventaire** (dépôts & colis).
6. **Paramètres** : commission, payouts, devise.
7. **Analytics fondateur**.

**Règles** : suppression définitive & factory reset = super_admin uniquement.

---

## Slide 6 — Statuts (mémorisation)

```
Booking : pending → confirmed → shipped → delivered | cancelled
Paiement : pending → completed | refunded
Shipment : active → completed | cancelled
Litige   : open → investigating → resolved | rejected
Colis    : stored → dispatched | returned
Tracking : order_processed → collected → departed_origin → in_transit
           → arrived_destination → customs_cleared → out_for_delivery → delivered
```

---

## Slide 7 — Données techniques

- Devise **DZD** · Commission **5 %** · Poids **0,1–50 kg** · Prix min **500 DZD/kg**
- Origines : Turquie, Chine, Dubaï, France, Italie, Espagne
- Destinations : Alger, Oran, Annaba, Constantine, Tlemcen, Sidi Bel Abbès, Béjaïa, Tizi Ouzou, Batna, Blida
- Pagination 20/page · Realtime activé · Buckets : profiles, documents, bookings, proofs
- UI française · RLS sur toutes les tables

---

> Ce document est le « content model » du widget `WorkflowSlider` (voir `lib/components/workflow_slider.dart`) : chaque slide = titre + étapes + règles, swipeable et paginé.