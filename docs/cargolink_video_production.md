# 🎬 CargoLink — Production Vidéo Complète
## Script + Storyboard + 3 Formats

> **Document de production professionnel** pour créer une vidéo premium qui **combine hook publicitaire + tutoriel** sur CargoLink. Tous les scripts, timing, shots, animations, musique, et SFX.

---

## 📋 Table des Matières

1. [Script Maître](#1-script-maître)
2. [Storyboard Détaillé](#2-storyboard-détaillé)
3. [Format 1 : YouTube (6-8 min)](#3-format-1--youtube-6-8-min)
4. [Format 2 : TikTok/Shorts (45 sec)](#4-format-2--tiktokreels45-sec)
5. [Format 3 : LinkedIn (1-2 min)](#5-format-3--linkedin-1-2-min)
6. [Notes de Production](#6-notes-de-production)

---

## 1. Script Maître

### Voix : narrateur algérien, ton confident & bienveillant
### Durée totale : 8 minutes (avant adaptation aux formats)
### Tempo : introduction lente → accélération progressive → appel à l'action

---

### **ACTE 1 — LE PROBLÈME (0:00–1:30)**

#### **[SCENE 1] Hook du problème**
```
NARRATEUR (voix off) :
« Vous avez commandé un colis en Chine ? En Turquie ? 
Un téléphone, des vêtements, des pièces détachées…
Et vous avez reçu une facture DHL ou FedEx qui vous a donné mal à la tête ?

Les frais d'importation, c'est 50 %, 60 %, parfois 100 % du prix du produit.
Et les micro-importateurs algériens ? Ils n'ont aucune plateforme pour proposer leurs services.
C'est inefficace. C'est cher. C'est frustrant. »
```

**Durée** : 30 sec  
**Visuel** : 
- Animation d'un **panier d'achat** qui se gonfle (scale in, staggered)
- Écran de facture FedEx qui **tremble** (shake animation)
- Nuage rouge avec prix qui augmente (counter animation)
- Fond dégradé rouge → orange (warningGradient de CargoLink)

**Audio** : Musique dramatique (minor key, 80 BPM)

---

#### **[SCENE 2] La frustration — interview clips**
```
NARRATEUR :
« Les clients attendent des jours, ne savent pas où est leur colis,
et paient une fortune. Ça doit changer. »
```

**Durée** : 20 sec  
**Visuel** : 
- 3 quick clips (1-2 sec chacun) de personas différents :
  1. **Client féminin** : « Je veux juste recevoir mon colis… »
  2. **Jeune importateur** : « J'ai des connexions en Turquie, mais comment commercialiser ? »
  3. **Admin logistique** : « On a pas les outils pour suivre tout ça. »
- Chaque clip en **FadeInOnScroll** (slide up + fade)

**Audio** : Musique ambiance légère (building tension)

---

### **ACTE 2 — LA SOLUTION (1:30–6:00)**

#### **[SCENE 3] Introduction CargoLink**
```
NARRATEUR :
« Rencontrez CargoLink. La première plateforme algérienne
qui connecte les voyageurs, les importateurs, et les clients.
Sécurisée. Transparente. Et 50 à 70 % moins chère que la concurrence. »
```

**Durée** : 15 sec  
**Visuel** : 
- Logo CargoLink avec **GradientBadge** (primaryGradient)
- Animation de **connexion** : 3 icônes (client, shipper, admin) qui se connectent par des lignes animées
- Chiffres : « –50 % » en grand (h1), « vs DHL/FedEx » (body secondaire)
- Transition : slide de gauche, apparition en cascade

**Audio** : Musique devient positive (major key, 90 BPM, synthé optimiste)

---

#### **[SCENE 4] Workflow Client (1:50–3:00)**

```
NARRATEUR :
« Voyons comment ça marche pour un client qui veut importer un produit.
Étape 1 : Rechercher une offre active.
Il voit tous les importateurs vérifiés, leurs destinations, leurs prix. »
```

**Durée** : 25 sec  
**Visuel** :
- Screenshot du téléphone (mockup) : écran d'accueil client
- **CustomScrollView** avec paged list animée (ShimmerCard au départ)
- Puis **PagedSliverList** charge 3-4 shipments avec **StaggeredEntrance** (delay 50ms entre chaque)
- Chaque carte : GlassCard, avatar expéditeur (GradientAvatar), destination/prix/note

**Animation détail** :
- Shimmer loading → FadeIn des cartes en cascade
- Chaque carte slide from bottom + fade
- Badge de prix avec **GradientBadge** (accentColor)

**Audio** : Narrateur fluide, musique légère de fond

---

```
NARRATEUR :
« Étape 2 : Réserver du poids.
Il choisit une offre, entre le poids et les photos de son produit.
Le prix s'affiche immédiatement. »
```

**Durée** : 20 sec  
**Visuel** :
- Tap sur une carte → Slide transition vers `/booking`
- Formulaire animé (champs en cascade avec StaggeredEntrance) :
  - Nom du produit (text field, focus animation)
  - Poids (number input avec increment/decrement buttons)
  - Photos (gallery upload avec thumbnail preview animée)
- Prix qui recalcule en **temps réel** (TweenAnimationBuilder, couleur accentColor)

**Animation détail** :
- Form fields apparaissent en cascade (60ms delay)
- Nombre de kg se met à jour avec scale animation (1.0 → 1.2 → 1.0)
- Prix total change avec FadeIn + slideIn animation

**Audio** : Bip sonore léger à chaque input (SFX)

---

```
NARRATEUR :
« Étape 3 : Payer.
Espèces, virement, CCP, Chargily, Stripe… Le choix est libre.
La transaction est sécurisée et confirmée instantanément. »
```

**Durée** : 15 sec  
**Visuel** :
- Écran payment (mockup) avec 5 boutons de méthode de paiement
- Chaque bouton en **AnimatedIconDot** (pulse léger)
- Tap sur Chargily → Loading animation (CircularProgressIndicator dégradé)
- Checkmark vert avec **Lottie animation** (success confetti)

**Animation détail** :
- Boutons d'animation au repos (pulse)
- Loading spinner : gradient animation
- Success : Lottie confetti + slide du checkmark

**Audio** : Ding ! positif à la validation

---

```
NARRATEUR :
« Étape 4 : Suivre en temps réel.
Une timeline de 8 étapes montre exactement où est votre colis.
À chaque mise à jour, vous recevez une notification. »
```

**Durée** : 25 sec  
**Visuel** :
- Écran `/tracking` (mockup complet)
- **Tracking timeline** : 8 points avec descriptions (order_processed → delivered)
- Indicateur de progression animé (FractionallySizedBox qui se remplit)
- Notifications push au bas de l'écran (2-3 notifications qui slide in et fade)

**Animation détail** :
- Timeline points s'animent au chargement (scale + fill color)
- Ligne de progression se remplit progressivement (AnimationController)
- Notifications slide from right, puis fade out après 3 sec
- Chaque étape passe de grise → accentColor quand complétée

**Audio** : Pop sonore discret à chaque notification, musique légère continue

---

#### **[SCENE 5] Workflow Expéditeur (3:00–4:30)**

```
NARRATEUR :
« Maintenant, le point de vue d'un jeune importateur.
Il veut publier une offre.
KYC vérifiée (passeport + selfie en direct), il est maintenant un shipper certifié. »
```

**Durée** : 20 sec  
**Visuel** :
- Écran de vérification KYC (mockup) :
  - Upload document (file picker animation)
  - Selfie en direct (caméra)
  - Badge de vérification ✓ en vert (GradientBadge)
- Dashboard shipper : stats (CA, offres, commandes) en cartes (GlassCard)

**Animation détail** :
- Document upload : scale transition + checkmark Lottie
- Stats cards apparaissent avec StaggeredEntrance (index*60ms)
- Chiffres s'animent (CounterAnimation de 0 → valeur réelle)

**Audio** : Validation positive (ding)

---

```
NARRATEUR :
« Il publie son offre : origine (Turquie, Chine, Dubaï…),
destination, poids disponible, prix par kilo.
L'offre est en ligne en secondes. »
```

**Durée** : 20 sec  
**Visuel** :
- Écran de publication (bottom sheet ou page dédiée)
- Formulaire : origines (dropdown avec 6 items qui slide), destinations (grid avec 10 villes), poids, prix
- Bouton « Publier » qui se remplit (RoundedLoadingButton style)
- Confirmation : offre apparaît dans le dashboard

**Animation détail** :
- Champs formulaire slide from bottom en cascade
- Dropdown animation : items slide up
- Bouton chargement : gradient rotating + fill
- Offre nouvelle slide into dashboard list

**Audio** : Notification positive (bell sound)

---

```
NARRATEUR :
« Les commandes arrivent. Il accepte, confirme l'expédition,
marque la livraison. À chaque étape, le client reçoit une notification.
Et le CA s'accumule, net de commission (5 %). »
```

**Durée** : 20 sec  
**Visuel** :
- Dashboard shipper : list des commandes en **PagedSliverList**
- Chaque commande : statut badge, poids, prix, boutons d'action
- Tap « Accepter » → Confirmation slide
- Revenue card mise à jour (counter animée)

**Animation détail** :
- Commandes chargent avec ShimmerCard puis StaggeredEntrance
- Badges statut s'animent (status workflow : pending → confirmed → shipped → delivered)
- Revenue counter actualise en temps réel (TweenAnimationBuilder)

**Audio** : Notifications douces, musique uplifting

---

#### **[SCENE 6] Dashboard Admin (4:30–5:30)**

```
NARRATEUR :
« Côté administration. Un dashboard 4 onglets : 
Expéditeurs, Litiges, Revenus, Inventaire.

Valider les KYC des nouveaux expéditeurs en un clic.
Gérer les litiges, les remboursements, les stocks. »
```

**Durée** : 30 sec  
**Visuel** :
- Tab bar avec 4 onglets : icônes + libellés
- Onglet 1 (Expéditeurs) : list avec filtres (pending, verified, rejected)
- Quick action : tap sur un expéditeur → modal de vérification
- Onglet 2 (Litiges) : list de litiges avec statuts
- Onglet 3 (Revenus) : graphique de CA (animation des barres)
- Onglet 4 (Inventaire) : map des dépôts + stock details

**Animation détail** :
- Tab transition : fade + slide
- List items : ShimmerCard → StaggeredEntrance
- Graphique CA : barres qui montent (ScaleTransition)
- Modal vérification : slide from bottom

**Audio** : Interface sounds discrets, musique neutre

---

### **ACTE 3 — APPEL À L'ACTION (5:30–8:00)**

#### **[SCENE 7] Récapitulatif & émotions**

```
NARRATEUR :
« CargoLink, c'est plus que des chiffres.
C'est une plateforme qui fait tomber les barrières.
Un jeune peut lancer son business d'import en 10 minutes.
Un client paie 50 % moins.
Et tout est traçable, sécurisé, en temps réel. »
```

**Durée** : 30 sec  
**Visuel** :
- Montage de 10-15 clips courts (2-3 sec chacun) :
  - Client qui confirme réception (smile, thumb up emoji)
  - Expéditeur qui check son CA en croissance
  - Admin qui approuve KYC
  - Notification de livraison
  - Reviews 5⭐
  - Partenaires (logolink Supabase, Stripe, Chargily)
- Background dégradé qui change (primaryGradient → successGradient)

**Animation détail** :
- Chaque clip fades in + scales (TweenAnimationBuilder)
- Emojis/icons pop (scale 0 → 1.2 → 1)
- Textes slide from sides

**Audio** : Musique orchestrale inspirante (crescendo)

---

#### **[SCENE 8] Call-To-Action**

```
NARRATEUR (tone plus direct) :
« Vous êtes client ? Trouvez le meilleur prix.
Vous êtes importateur ? Lancez votre business.
CargoLink est sur iOS et Android.

Téléchargez maintenant. »
```

**Durée** : 15 sec  
**Visuel** :
- Split screen : iPhone (left) + Android (right) avec l'app ouverte
- App store & Play Store badges brillants (glow effect)
- QR code animé (pulse)
- Logo CargoLink final avec tagline

**Animation détail** :
- Téléphones slide from sides
- Badges pulse et glow
- QR code : rotation + glow
- Logo final : zoom out + fade in

**Audio** : Musique finale (dernière 3 secondes)

---

#### **[SCENE 9] Fin / Outro**

```
NARRATEUR (voix chaleureuse) :
« CargoLink. Connecter. Importer. Transformer.

Construisons ensemble le commerce algérien du futur. »
```

**Durée** : 10 sec  
**Visuel** :
- Logo + tagline statique (ou très légère animation, scale + glow)
- Liens : www.cargolink.dz | YouTube channel | Instagram @cargolink.dz

**Audio** : Fin musicale douce (fade out)

---

## 2. Storyboard Détaillé

### Format : Image mentale + Timing + Transitions

| Scène | Timing | Shot | Transition | Animation | Audio | Notes |
|-------|--------|------|-----------|-----------|-------|-------|
| 1 — Hook | 0:00–0:30 | Macro : panier, facture, prix | Fade in | Panier scale up, facture shake, prix counter | Musique dramatique | Établir l'urgence |
| 2 — Interviews | 0:30–0:50 | 3× clips courts (portraits) | Slide up + fade | FadeInOnScroll sur chaque | Clips audio dub | Personas variés |
| 3 — Logo intro | 0:50–1:05 | Logo CargoLink + 3 icônes | Fade in dégradé | Icons connectées par lignes animées | Bell ding | Présentation solution |
| 4 — Client home | 1:05–1:30 | Mockup phone (client home) | Slide from left | ShimmerCard → StaggeredEntrance des cartes | Slide sound + musique légère | Démonstration fluide |
| 5 — Booking form | 1:30–1:50 | Mockup phone (booking) | Swipe transition | Fields cascade (StaggeredEntrance) | Tap sounds, musique continue |  |
| 6 — Paiement | 1:50–2:05 | Mockup phone (payment methods) | Zoom in | Buttons pulse (AnimatedIconDot), Lottie success | Ding validation | Satisfying feedback |
| 7 — Timeline tracking | 2:05–2:30 | Mockup phone (tracking) | Slide up | Points animent, ligne remplit, notifications slide | Pop sounds, notification SFX | Real-time feel |
| 8 — Shipper KYC | 2:30–2:50 | Mockup phone (KYC) | Fade transition | Upload animation, checkmark Lottie | Validation sounds | Certification important |
| 9 — Shipper publish | 2:50–3:10 | Mockup phone (publish form) | Slide down | Form fields cascade, button loading | Notification bell | Workflow clair |
| 10 — Shipper commandes | 3:10–3:30 | Mockup phone (commands) | Swipe | List ShimmerCard → StaggeredEntrance | Musique uplifting | CA en temps réel |
| 11 — Admin KYC | 3:30–4:00 | Mockup phone (admin tab 1) | Slide left | Tab transition, list items cascade, modal appear | Interface sounds | 4 onglets preview |
| 12 — Admin disputes | 4:00–4:15 | Mockup phone (admin tab 2) | Fade transition | List items SlideUp, badge animations | Soft bell | Gestion simplifiée |
| 13 — Admin revenue | 4:15–4:30 | Mockup phone (admin tab 3) | Slide transition | Graphique barres scale up (CounterAnimation) | Ascending tone | Données vitales |
| 14 — Montage émotions | 4:30–5:00 | 15× clips rapides (portraits, notifications, reviews) | Rapid cuts + crossfade | Pop animations, emojis scale, text slide | Musique crescendo orchestrale | Energy montante |
| 15 — CTA iOS/Android | 5:00–5:15 | Split screen iPhone/Android | Slide from sides | Phones zoom, badges pulse, QR glow | Crescendo final | Direct download |
| 16 — Logo final | 5:15–5:30 | Logo statique ou glow subtle | Fade + zoom | Logo pulse glow | Musique fade out | Branding fort |

---

## 3. Format 1 : YouTube (6-8 min)

### Strategy
- **Full narrative** : problem → solution → workflow complet → CTA
- **Platform** : algo favorise watch time → sections bien structurées
- **Title** : "Comment importer 50% moins cher en Algérie ? CargoLink expliqué"
- **Description** : Lien d'accroche + timestamps + CTA

### Script YouTube (8 min)

```markdown
## INTRO (0:00–0:30)
[Hook visuel] : Facture DHL + chiffre -50%

NARRATEUR :
"Vous avez commandé un colis en ligne et reçu une facture
de frais d'importation hallucinante ?
Ça change aujourd'hui."

[TITRE : CargoLink]

---

## PROBLÈME (0:30–2:00) [TIMESTAMPS]
[Musique dramatique, interviews rapides]

NARRATEUR :
"Les frais DHL ? 50 à 100% du prix du produit.
Les importateurs algériens n'ont pas de plateforme.
Les clients attendent des jours sans savoir où est leur colis.

C'est cher. C'est inefficace. C'est frustrant."

[3-4 testimonials courtes]

---

## SOLUTION (2:00–3:00)
[Logo CargoLink]

NARRATEUR :
"CargoLink est la première plateforme algérienne
qui connecte clients et micro-importateurs.
50 à 70% moins cher. Transparent. En temps réel."

---

## WORKFLOW CLIENT (3:00–5:00)
[Mockups détaillés, slow enough to follow]

NARRATEUR (écrit + énumère les étapes) :

1️⃣ RECHERCHER (1:00–1:30)
   "Vous recherchez une offre active.
    Vous voyez tous les importateurs certifiés,
    leurs destinations, leurs prix."
   [Mockup : client home, paged list]

2️⃣ RÉSERVER (1:30–2:00)
   "Vous entrez le poids et les photos.
    Le prix s'affiche immédiatement."
   [Mockup : booking form, animations]

3️⃣ PAYER (2:00–2:20)
   "Plusieurs méthodes : espèces, virement, Chargily, Stripe.
    La transaction est validée en secondes."
   [Mockup : payment, success animation]

4️⃣ SUIVRE (2:20–3:00)
   "Une timeline vous montre exactement où est votre colis.
    8 étapes, notifications en direct."
   [Mockup : tracking timeline, notifications]

---

## WORKFLOW EXPÉDITEUR (5:00–6:00)
[Mockups shipper dashboard]

NARRATEUR :
"Un jeune importateur : 
KYC vérifiée, il publie son offre en 2 minutes.
Les commandes arrivent, il accepte, expédie, livre.
Son CA s'accumule. Transparent. Facile."

[Dashboard, publish flow, revenue growth]

---

## DASHBOARD ADMIN (6:00–6:30)
[Quick preview des 4 onglets]

NARRATEUR :
"Côté administration : vérifier les KYC,
gérer les litiges, suivre les revenus, gérer l'inventaire.
Tout en un seul endroit."

---

## APPEL À L'ACTION (6:30–7:30)
[Montage émotions : portraits, reviews, notifications]

NARRATEUR (inspirant) :
"CargoLink, c'est plus que des chiffres.
C'est une plateforme qui libère le commerce algérien.
Un jeune peut lancer son business en 10 minutes.
Un client paie 50% moins.
Tout est tracé. Tout est sûr."

[CTA visuel : iPhone + Android stores]

---

## OUTRO (7:30–8:00)
[Logo final]

NARRATEUR :
"CargoLink. Connecter. Importer. Transformer.
Téléchargez dès maintenant sur iOS et Android.

Lien dans la description."

[Musique finale, logo glow]
```

### YouTube Metadata
- **Title** : "CargoLink — Importer 50% Moins Cher en Algérie | Tutoriel Complet"
- **Description** :
  ```
  🚀 Découvrez CargoLink, la première plateforme algérienne 
  qui révolutionne l'import !

  ⏰ TIMESTAMPS :
  0:00 Hook — Le problème
  0:30 Interviews
  2:00 Présentation CargoLink
  3:00 Workflow Client
  5:00 Workflow Expéditeur
  6:00 Dashboard Admin
  6:30 Appel à l'action
  7:30 Outro

  📱 TÉLÉCHARGER :
  iOS : [lien AppStore]
  Android : [lien PlayStore]

  🌐 Plus d'infos : www.cargolink.dz
  📧 Support : support@cargolink.dz
  ```
- **Tags** : cargolink, algérie, import, logistique, tutoriel, entreprise, commerce
- **Thumbnail** : Logo CargoLink + « –50% » rouge + Drapeau Algérie

---

## 4. Format 2 : TikTok/Reels (45 sec)

### Strategy
- **Hook first 3 sec** : Must stop the scroll
- **Platform** : Vertical video, trending sounds, snappy cuts
- **Focus** : Le wow factor du problème + solution simple

### Script TikTok (45 sec)

```markdown
## OPENING HOOK (0:00–0:03)
[Full-screen RED avec chiffre]
"DHL vous a envoyé une facture de : 15 000 DA ?"

TEXT ON SCREEN : "Ça change maintenant 👇"

SOUND : Dramatic synth drop + trending audio TikTok

---

## PROBLEM (0:03–0:10)
[Quick cuts]
- Facture DHL choc
- Client dépité
- Importateur frustré
- Admin débordé

TEXT : "Le problème ?"
SOUND : Tense stabs

---

## SOLUTION (0:10–0:15)
[Logo CargoLink + gradient]

TEXT (on screen) : "CargoLink"
VOICE : "–50 à –70% moins cher"

SOUND : Inspiring synth rise

---

## DEMO (0:15–0:40)
[Fast cuts de l'app]

1. Recherche offre (0:15–0:20)
   [Mockup : app swipe, cards appear]
   TEXT : "1. Recherche"

2. Réserve (0:20–0:25)
   [Mockup : booking form filled, price popup]
   TEXT : "2. Réserve"

3. Paye (0:25–0:30)
   [Mockup : payment success Lottie]
   TEXT : "3. Paie"
   SOUND : Ding satisfaction

4. Suivi (0:30–0:40)
   [Mockup : tracking live, notification popup]
   TEXT : "4. Suis en direct"
   SOUND : Notification sound

---

## CTA (0:40–0:45)
[Store badges slide in]

TEXT (top) : "Télécharge maintenant"
TEXT (bottom) : "CargoLink | iOS & Android"

SOUND : Uplifting finale + call-to-action synth

[Link in bio sticker]
```

### TikTok Metadata
- **Caption** :
  ```
  CargoLink révolutionne l'import en Algérie 🚀
  –50% vs DHL/FedEx
  
  Aucune commission cachée.
  Suivi en direct.
  Tous les paiements acceptés.
  
  Lien en bio ⬇️ #Algérie #Commerce #Import #Startup
  ```
- **Hashtags** : #CargoLink #Algérie #Commerce #Import #Supabase #Startup #Logistics #SmallBusiness
- **Trend Audio** : Synth inspirant populaire sur TikTok (ex. "Oh No" remix, ou audio original)
- **Cover** : Red + Logo + "–50%"

---

## 5. Format 3 : LinkedIn (1-2 min)

### Strategy
- **Professional tone** : Founder story + impact
- **Audience** : Entrepreneurs, investors, B2C
- **Focus** : Testimonial + business opportunity

### Script LinkedIn (1:50)

```markdown
## OPENING (0:00–0:10)
[Founder on camera, casual professional]

FOUNDER (your voice) :
"Mon nom est [Nom], et j'ai créé CargoLink parce que
j'en avais assez de voir les Algériens payer 2× le prix réel
pour importer un produit simple."

---

## PROBLEM (0:10–0:40)
[B-roll : factures, importateurs, clients]

FOUNDER (VO) :
"Les frais DHL/FedEx étouffent les petits importateurs.
Aucune plateforme fiable pour faire la liaison.
Les clients attendent des jours sans traçabilité.

Ça doit changer."

---

## SOLUTION (0:40–1:00)
[App screens, professional font]

FOUNDER (VO) :
"CargoLink connecte clients et micro-importateurs algériens.
–50 à –70% moins cher. Temps réel. Sécurisé.
Construit avec Supabase, Stripe, et Flutter.

Aujourd'hui : 500+ utilisateurs et croissance 30% mois."

[Stats appear on screen : 500+, 30%, 4.8⭐]

---

## IMPACT (1:00–1:40)
[Testimonials vidéo ou texte]

Client (screenshot/video) :
"J'ai économisé 25 000 DA sur ma commande de téléphones. 
Merci CargoLink !"

Shipper (screenshot/video) :
"J'ai créé mon business d'import sans apport initial.
Plateforme super intuitive."

---

## CTA (1:40–1:50)
[Founder back on camera]

FOUNDER :
"Si vous êtes importateur ou entrepreneur en Algérie,
rejoignez-nous. Le commerce algérien se digitalise.

Lien en premier commentaire."

---

## OUTRO (1:50)
[Logo + tagline]
"CargoLink. Connecter. Importer. Transformer."
```

### LinkedIn Metadata
- **Post Caption** :
  ```
  🚀 Lancer un business d'import sans apport initial.

  CargoLink a commencé par une frustration simple :
  pourquoi les Algériens paient-ils 2× le prix 
  pour importer un produit simple ?

  En 6 mois :
  ✅ 500+ utilisateurs actifs
  ✅ 30% croissance mois/mois
  ✅ Partenaires : Supabase, Stripe, Chargily
  ✅ Paiement 50-70% moins cher que DHL/FedEx
  ✅ 4.8⭐ (Google Play & App Store)

  Si vous cherchez à :
  👉 Lancer un business d'import
  👉 Envoyer des colis moins cher
  👉 Rejoindre une startup tech algérienne
  
  Téléchargez CargoLink → Lien dans le premier commentaire

  Un merci spécial à l'équipe pour ce travail incroyable
  sur les animations, la UX, et l'infrastructure.

  L'Algérie a des talents. L'Algérie a besoin d'outils modernes.
  CargoLink en est un.

  #CargoLink #Algérie #Startup #Commerce #Import 
  #Flutter #Supabase #Entrepreneurship
  ```
- **Tags** : #CargoLink #Startup #Algérie #Entrepreneurship #Commerce #Technology
- **Image** : Founder photo + logo CargoLink (16:9, professional)

---

## 6. Notes de Production

### 6.1 Musique & SFX

| Moment | Musique | BPM | Genre | Mood |
|--------|---------|-----|-------|------|
| Intro (hook) | Synth drama minor key | 80 | Cinématique | Tension |
| Interviews | Building tension ambient | 70 | Ambient | Sombre |
| Logo intro | Major key uplifting | 95 | Synthpop | Espoir |
| Demo flows | Légère uplifting | 110 | Electronic | Confiant |
| Montage émotions | Orchestrale crescendo | 120 | Orchestral | Inspirant |
| CTA & outro | Positive synth resolution | 100 | Synthwave | Satisfait |

**SFX** :
- Tap sounds : soft click (notification-style)
- Loading : subtle whoosh
- Success : bell ding (positive)
- Error/alert : gentle buzz
- Notification : pop sound

**Royalty-free sources** : Epidemic Sound, Artlist, YouTube Audio Library

---

### 6.2 Design Assets Requis

#### Screenshots (Mockups)
1. **Client Home** : dark/light theme, paged list visible
2. **Booking Form** : fields, number input, photo upload
3. **Payment Screen** : 5 payment methods, loading state
4. **Tracking Timeline** : 8 steps, progress bar, notifications
5. **Shipper Dashboard** : stats cards, commands list
6. **Publish Offer** : form with dropdowns, confirmation
7. **Admin Dashboard** : 4 tab bar, each tab showing data
8. **KYC Screen** : document upload, selfie, verification badge

**Style** : Utiliser les tokens CargoLink :
- `primaryGradient` (#6366F1 → #8B5CF6)
- `accentColor` (#10B981)
- `warningColor` (#F59E0B)
- `AppTheme.cardDecoration()` pour les cards
- Animations : `StaggeredEntrance`, `ShimmerCard`, `GlassCard`, `AnimatedIconDot`

#### Visuals (Graphics)
- Logo CargoLink (avec tagline si nécessaire)
- 3 icônes pour hero : client (person), shipper (delivery), admin (settings)
- Drapeau Algérie (pour tagline « Made in Algeria »)
- App store badges (iOS AppStore, Google PlayStore)
- QR code (vers page d'accueil ou store)

#### Photos
- 3-4 personas (client, shipper, admin, founder) pour testimonials
- Si possible : portraits authentiques (non-AI, c'est plus crédible)

---

### 6.3 Animation Checklist

- [ ] **StaggeredEntrance** : tous les items de liste (delay 50-60ms)
- [ ] **ShimmerCard** : loading state avant data
- [ ] **AnimatedIconDot** : pulse sur badges de statut
- [ ] **GradientBadge** : badges de prix/statut (no animation, static)
- [ ] **TweenAnimationBuilder** : nombres qui changent (CA, prix, count)
- [ ] **ScaleTransition** : zoom on buttons/success
- [ ] **FadeInOnScroll** : optional, apparition en scroll
- [ ] **Lottie** : success checkmark, confetti
- [ ] **CounterAnimation** : statistiques (500+ users, 30% growth)
- [ ] **LineChartAnimation** : CA graph (barres qui montent)

---

### 6.4 Editing & Post-Production

**Software** : Adobe Premiere Pro, DaVinci Resolve, ou Capcut (mobile)

**Workflow** :
1. Importer tous les clips de mockups, interviews, graphics
2. Assembler timeline selon storyboard
3. Ajouter transitions (fade, dissolve, slide)
4. Sync musique à tempo
5. Ajouter SFX aux moments clés
6. Couleur grade : uniformité et « premium feel »
7. Exporter 3 versions :
   - YouTube : 1920x1080 (16:9), 60fps, H.264
   - TikTok/Reels : 1080x1920 (9:16), 30fps, H.264
   - LinkedIn : 1200x627 (16:9) et vertical 1080x1350

---

### 6.5 Distribution Strategy

#### YouTube
- Upload 1 semaine avant grosse promo
- Partager sur :
  - LinkedIn
  - Reddit (r/Algeria, r/Entrepreneurship)
  - Twitter/X (@CargoLink_DZ)
  - WhatsApp broadcast

#### TikTok/Reels
- Post 3× par semaine pendant le lancement
- Trend sounds de la semaine
- Hashtags viraux

#### LinkedIn
- Post 1× par semaine
- Encourage team members à share/react
- Pitch aux investisseurs Algériens

---

### 6.6 Metrics à Tracker

- **YouTube** : watch time, retention, click-through rate (CTA links)
- **TikTok** : views, shares, saves, profile visits
- **LinkedIn** : impressions, engagements, profile visits, clicks
- **App installs** : tracking via UTM params (utm_source=video_youtube, etc.)

---

## Résumé Exécutif

| Format | Durée | Hook | Focus | CTA |
|--------|-------|------|-------|-----|
| YouTube | 6-8 min | Facture DHL choc | Workflow complet + case studies | App stores + Website |
| TikTok | 45 sec | –50% quick win | Demo rapide + reviews | Bio link |
| LinkedIn | 1:50 | Founder story | Impact + stats + opportunity | First comment link |

---

**Prochaines étapes** :
1. Produire les screenshots/mockups avec CargoLink app
2. Filmer les testimonials (ou utiliser des portraits de stock fiables)
3. Choisir musique/SFX
4. Assembler dans éditeur vidéo
5. QA (color, sound, text overlays)
6. Exporter 3 formats
7. Programmer uploads & promotion

**Estimated timeline** : 2-3 semaines (conception + production + post-prod)

---

Generated for Connacri | CargoLink Productions | August 2026
