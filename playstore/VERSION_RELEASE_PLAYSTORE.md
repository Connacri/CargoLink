# VERSION RELEASE PLAYSTORE

> Ce fichier est **mis à jour après chaque commit** : il décrit toujours la version
> courante prête pour la Google Play Console, le build à déposer et tout ce qui a été
> fait pour la Play Store dans cette version.

---

## Dernière version

| Élément | Valeur |
|---|---|---|
| Version (versionName) | **1.1.35** |
| Code de version (versionCode) | **257** (monotone, obligatoirement croissant entre 2 dépôts) |
| Commit de référence | `68214ff` |
| Statut CI | À publier au prochain push → release `v1.1.35` sur GitHub |
| Type de build | **App Bundle (.aab) signé** — seul format accepté par la Play Console |
| Fichier à déposer | `app-release.aab` (≈ 84 Mo) |
| Origine du fichier | GitHub Release (workflow `release.yml`, job `android-aab`) |
| Nom du package | `com.cargolink.dz.cargolink` (aligné sur `google-services.json`, nécessaire pour Firebase/push) |
| SDK cible | Android 13 (API 36) compilé dans la CI (`platforms;android-36`) |

**Télécharger le bundle** (remplacer `X.Y.Z` par la version ci-dessus) :
```
https://github.com/Connacri/CargoLink/releases/download/vX.Y.Z/app-release.aab
```

**Canal de test conseillé** : Play Console → « Test interne » d'abord (sécurité),
puis « Test fermé » avec des bêta-testeurs, puis Production.

---

## Description Play Store

### Description courte (78 caractères — max 80)

```
CargoLink : expediez et suivez vos colis en Algerie, avec livraison securisee.
```

### Description complète (4000 caractères exactement)

```
CargoLink est la premiere application algerienne dediee a l'expedition et au suivi de colis entre particuliers et professionnels. Que vous soyez un particulier envoyant un colis a un proche ou un commercant gerant vos livraisons au quotidien, CargoLink simplifie chaque etape du processus d'expedition grace a une interface intuitive et des fonctionnalites completes pensees pour les utilisateurs en Algerie. Pour les expediteurs, CargoLink offre la possibilite de publier des offres d'expedition en quelques clics en renseignant le poids disponible, l'origine, la destination et les dates de depart et d'arrivee. Les transporteurs verifies proposent ensuite leurs tarifs et conditions, permettant a l'expediteur de comparer les offres et de reserver celle qui correspond le mieux a ses besoins et a son budget. Chaque transporteur est soumis a un processus de verification rigoureux incluant la validation de la piece d'identite et d'une photo, garantissant ainsi la securite et la confiance entre les parties. Le suivi en temps reel constitue l'un des piliers de CargoLink. Grace a un systeme de timeline detaille, chaque etape de la livraison est visible : reception du colis, mise en transit, arrivee au depot de destination, et livraison finale au destinataire. A chaque changement de statut, une notification push informe automatiquement le client de l'avancement de son colis. Un historique complet et detaille de toutes les expeditions est accessible a tout moment, offrant une transparence totale sur le parcours des marchandises. La messagerie integree permet aux expediteurs et transporteurs de communiquer directement dans l'application sans avoir a partager leurs coordonnees personnelles. Les echanges sont synchronises en temps reel avec des notifications push pour ne manquer aucune reponse, que ce soit pour organiser un point de retrait ou pour clarifier les details d'une livraison. CargoLink met a disposition un reseau de depots de collecte repartis sur tout le territoire algerien. Ces points relais facilitent la remise et le retrait des colis, offrant une flexibilite maximale aux utilisateurs. L'inventaire de chaque depot est maintenu a jour en temps reel pour eviter toute mauvaise surprise. Le paiement se fait selon plusieurs modalites adaptees aux habitudes locales : especes a la livraison, virement bancaire, CCP ou paiement en ligne securise via des prestataires agres. Cette diversite de choix permet a chaque utilisateur de selectionner la methode qui lui convient le mieux. Le programme de parrainage recompense la fidelite et le bouche-a-oreille : chaque parrain genere un code personnel unique qu'il partage avec ses contacts. Lorsqu'un filleul effectue sa premiere livraison, le parrain recoit une commission sur les gains realises. Un tableau de bord dedie permet de suivre en temps reel les filleuls parraines, les commissions accumulees et l'historique des paiements. Les utilisateurs peuvent signaler tout probleme ou suggerer des ameliorations via un formulaire de feedback integre, contribuant ainsi a l'amelioration continue de la plateforme. Chaque retour est analyse par l'equipe pour garantir une experience utilisateur toujours plus fluide. Un tableau de bord administrateur complet permet de gerer les utilisateurs, les annonces, les depots et les finances de la plateforme. Les fonctionnalites avancees incluent la verification des transporteurs, la gestion des litiges, le suivi des commissions et des paiements, ainsi que l'envoi de broadcasts aux utilisateurs. CargoLink s'engage sur la protection des donnees personnelles avec un chiffrement HTTPS obligatoire sur toutes les communications, aucune collecte de localisation GPS et une politique de confidentialite transparente accessible directement dans l'application. La suppression de compte est integree pour un controle total des donnees personnelles. Telechargez CargoLink aujourd'hui et decouvrez une nouvelle facon simple, securisee et en toute confiance d'expedier vos colis en Algerie.
```

---

## Contenu de cette version (nouveautés Play Store / fonctionnalités)

### Version 1.1.35

- **Notifications push routées vers le bon écran** : un appui sur une
  notification (app ouverte, en arrière-plan ou fermée) ouvre désormais le
  suivi du colis pour le client et les administrateurs, et le détail de la
  réservation pour l'expéditeur. Si l'utilisateur n'est pas connecté, la
  notification est mise en attente et ouverte juste après la connexion.
- **Suivi de colis en temps réel** : la frise de suivi (statut, progression,
  points de suivi) se met à jour en direct dans l'écran de suivi et dans
  « Mes colis », sans quitter l'écran — nouvelle étape livraison, arrivée,
  livraison renseignées par l'expéditeur apparaissent immédiatement.
- **Noteurs in-app cliquables côté client** : les notifications de
  réservation (acceptation, poids, suivi…) de l'écran d'accueil client
  ouvrent maintenant le suivi du colis.
- **Pages administrateur en temps réel** : centre de vérification KYC,
  transactions, boîte de feedback, tableaux de bord admin et fondateur
  (compteurs, listes, chiffres), inventaire/dépôts, publicités, commissions,
  abonnements, parrainage et analytics se rafraîchissent en direct à chaque
  changement en base.
- **Détails client/expéditeur synchronisés** : paiement (statut, promo,
  wallet), détail d'offre (capacité restante, prix), demandes de livraison
  (client et expéditeur), profil et dashboard parrainage suivent les mises à
  jour en temps réel.

### Version 1.1.34

- **Workflow « écart de poids » pendant la vérification (ref/QR inchangés)** :
  si le colis réel n'a pas le poids demandé, l'expéditeur refuse la réservation
  avec « Écart de poids » → le statut passe `waiting_client_update` et le client
  reçoit une notification push + une bannière sur son écran d'accueil et dans le
  suivi (« Corriger le poids »). La correction se fait dans une feuille dédiée
  (recalcul automatique du montant et de la commission), la demande repart en
  vérification (`awaiting_verification`) **sans changer le n° de suivi ni le QR**,
  puis l'expéditeur est notifié que le poids a été corrigé.
- **Bannière « demande acceptée » sur le home client** : quand une réservation
  est acceptée par l'expéditeur, un bandeau succès « Demande acceptée ! » (avec
  lien direct vers le suivi/QR) apparaît en haut de l'accueil client.
- **Bannière « demandes de réservation reçues » sur le home expéditeur** :
  bandeau flottant indiquant le nombre de nouvelles demandes en attente, qui
  mène directement à la première demande et disparaît une fois une demande
  ouverte.
- **Dialog « Billet de réservation » enrichi** : suppression des deux cartes
  « IMPORTANT » (redondantes), photos du produit agrandissables (plein écran,
  zoom + swipe), actions « Fermer / Enregistrer » et bouton « Voir le détail
  complet » selon le contexte (expéditeur → détail commande, client → suivi).
- **Fusion des étapes de vérification** : une fois le colis collecté, l'action
  devient directement « Finaliser la vérification » (étape séparée supprimée) ;
  l'écran de vérification s'affiche avec un titre vert.
- **Wording cohérent « réservation »** : bouton « Réservé » à l'étape finale du
  wizard client, « Accepter la réservation » (au lieu de « Confirmer la
  commande ») et « Demandes de réservation reçues » sur le tableau de bord
  expéditeur.
- **Prise de preuve photo « caméra seule »** : la collecte du colis lance la
  caméra arrière directement (sans passer par le tiroir galerie/caméra), pour
  accélérer la prise de photo sur le terrain.
- **Masquage des lignes label/valeur vides** : les lignes optionnelles
  (courrier, n° de suivi, compagnie, vol…) ne s'affichent que si la valeur est
  non vide sur les écrans de détail et de suivi.

### Version 1.1.33

- **Billet d'avion complet dans chaque offre publiée (tous les rôles)** : le
  vrai billet CargoLink (aéroport de départ, aéroport d'arrivée **et ville
  d'arrivée clairement affichée** sous l'aéroport, compagnie, n° de vol,
  dates, poids disponible, prix/kg, téléphone expéditeur cliquable) s'affiche
  désormais dans **toutes** les offres publiées — feed client
  (`ShipperCard`), profil public expéditeur (offres actives), tableau de bord
  expéditeur (offres publiées) et liste des envois admin. Le billet est
  **flexible** (s'adapte à la largeur de l'écran) et réutilise le même
  composant que le partage social via un helper unique `OfferShareService.ticketFor`.
  Le code mort (`FlightRouteCard`, `_AirportCard`) a été supprimé.
- **Chaque numéro de téléphone est cliquable (appel direct `tel:`)** dans
  tous les écrans et rôles, avec **label masqué et zéro espace vide quand le
  numéro est absent** — ticket d'offre, détail offre, profils publics client
  et expéditeur, détail user admin, inventaire admin, scan QR, commandes
  expéditeur (détail + stats), gestion de compte. Nouveau widget
  `TappablePhone` (exporté par `ui_kit`).
- **Fix UX — dialog « Billet de réservation » (clic QR dans Mes colis /
  Suivi)** : la zone « IMPORTANT » était transparente/illisible. La dialog est
  redessinée sur une surface dégradée indigo (`primaryLighter`), le billet
  blanc ressort nettement, et l'en-tête répétée a été retirée — rendu
  professionnel et cohérent avec le design system.
- **Fix débordements du billet** : l'en-tête et les lignes du billet
  compressent (Flexible/ellipsis) au lieu de déborder sur les petits écrans
  ou gros réglages de police.
- **Google Sign-In (support Play Store)** : ajout pour un futur diagnostic
  (non activé).

### Version 1.1.15

- **Refonte complète du home fondateur (UX premium)** : le tableau de bord
  fondateur est réorganisé en sections claires et hiérarchisées, **sans aucune
  suppression de fonctionnalité** :
  - **Héro d'accueil** : carte dégradée indigo avec salutation contextuelle
    (« Bonjour / Bon après-midi / Bonsoir »), **total des actions à traiter** en
    valeur forte et chips cliquables par type (Vérifications, Commissions,
    Publications, Publicités, Suppressions, Feedback) menant à chaque écran de
    traitement.
  - **Accès rapide** : grille tactile de 8 cartes (Vérifications, Commissions,
    Suppressions, Publications, Publicités, Abonnements, Feedback, Parrainages)
    avec icône dégradée, label et **badge de compteur en direct**.
  - **Sections groupées avec titres** : « Vue d'ensemble » (KPIs), Parrainage,
    « Finance » (Portefeuille), « Gestion » (Packs d'abonnement + Articles
    interdits), « À traiter » (vérifications, publicités, publications,
    commissions, suppressions, abonnements, feedback).
  - Toutes les actions existantes restent accessibles (confirmation inline,
    accès rapides, écrans dédiés).

### Version 1.1.14

- **Fix CI — les builds ne se déclenchaient plus** : le workflow `release.yml`
  était rejeté en 0 s et **aucune release n'était plus buildée à chaque push**.
  Cause : `secrets` utilisé illégalement dans le `if` du job iOS (interdit par
  GitHub Actions → workflow entier invalide). Correction : ajout d'un job
  `ios-check`   qui lit les secrets via `env` (autorisé) et expose un `output`,
  sur lequel le job iOS se base désormais. Le workflow se déclenche de nouveau
  à chaque commit/push sur `master` (AAB + APK signés, Windows, web) et crée la
  release GitHub. Le job iOS reste optionnel et ne bloque pas l'Android.
- **Fix CI iOS — cible de déploiement 15.0** : `google_maps_flutter_ios`
  (v2.18.4) exige iOS 15.0 minimum ; `pod install` échouait en CI. La cible de
  déploiement passe de 13.0 à 15.0 (Podfile `platform :ios, '15.0'` +
  `IPHONEOS_DEPLOYMENT_TARGET`), rendant le job iOS buildable sous CocoaPods.
- **Job iOS désactivé** : sans compte Apple Developer payant, le certificat
  `.p12` fourni est invalide (échec d'import à la signature). Le job `ios` (et
  son `ios-check`) est mis à `if: false` pour garder le workflow vert ; la
  Release Android (AAB/APK) reste publiée à chaque push et n'est pas bloquée par
  iOS. Réactivation documentée dans le workflow quand un vrai certificat est
  fourni.
- **Dashboard fondateur — bloc KPI « Activité & Finance »** : nouvelle rangée
  de 6 indicateurs sous la vue d'ensemble existante — **Vols actifs**,
  **Commandes en cours**, **CA encaissé (global)**, **Commissions réglées**,
  **Commissions dues** et **Expéditeurs actifs (30 j)** — calculés à partir des
  données déjà chargées (aucune requête backend supplémentaire).

### Version 1.1.13

- **Gestion des « Articles interdits » (fondateur)** : le fondateur gère
  désormais la liste des articles interdits vérifiés lors du contrôle colis
  depuis une nouvelle entrée « Articles interdits » du tableau de bord (carte
  rouge, icône bloc). L'écran permet d'**ajouter** un article (nom + catégorie),
  de le **réordonner par glisser-déposer**, de l'**activer/désactiver**, de le
  **modifier** et de le **supprimer**. La liste est stockée dans la table
  Supabase `forbidden_items` (lecture publique des actifs, écriture réservée
  admin/super_admin via RLS).
- **Feuille de vérification colis dynamique (expéditeur)** : la liste des
  articles interdits de la vérification colis n'est plus codée en dur — elle se
  charge depuis `forbidden_items` (articles actifs, ordre du fondateur). Un
  repli sur la liste par défaut s'affiche si la table est vide ou inaccessible.
  Le poids réel et le motif de renvoi restent inchangés.

### CI — build iOS signé (optionnel)

- **Packs d'abonnement affichés correctement selon le rôle et souscription** :
  la feuille « Choisissez votre abonnement » affiche désormais les bons packs selon le
  rôle (client → pack « Black » ; expéditeur → Silver/Gold/Platinum) et permet à
  l'utilisateur de **s'abonner** (création d'une demande `pending` validée ensuite par
  le fondateur). Le rendu des cartes de pack est fiabilisé (enveloppe `Material`) et le
  rôle transmis est normalisé (minuscules/trim). Le bandeau d'abonnement du profil est
  affiché tant pour les clients que pour les expéditeurs. Les données des packs sont
  rafraîchies (invalidation) après création/modification/suppression côté fondateur.
- **Parsing robuste des packs** : `SubscriptionPack.fromJson` accepte les nombres
  encodés en chaîne (prix/durée) et ne lève plus d'exception, évitant un écran vide
  silencieux.

### CI — build iOS signé (optionnel)

> Infra (n'impacte pas le versioning de l'app Android) : le workflow `release.yml`
> inclut un job `ios` (runner `macos-latest`) qui produit un **IPA signé**
> (`app-store-connect` ou `ad-hoc` pour distribuer en externe sans store). Le
> `ios/Podfile` a été ajouté (cible iOS 13.0, plugins natifs).
>
> Ce job est **OPTIONNEL** : il ne tourne que si les secrets `IOS_*` sont définis
> (`IOS_CERTIFICATE_P12_BASE64`, `IOS_CERTIFICATE_PASSWORD`,
> `IOS_PROVISIONING_PROFILE_BASE64`, `IOS_TEAM_ID`, `IOS_KEYCHAIN_PASSWORD`).
> Sans compte Apple Developer payant, il est ignoré **et ne bloque pas** la
> Release Android. Signature gratuite possible sur ses propres appareils via
> AltStore/Sideloadly (re-signature 7 j, non externe).

### Version 1.1.11

- **Abonnement consolidé sur les packs (suppression de l'ancien système prix fixes)** :
  l'intégralité de l'abonnement repose désormais sur les **packs** configurés par le
  fondateur. Les réglages plateforme « Abonnements » (prix client / expéditeur / durée)
  et le repli `_FallbackPack` ont été supprimés ; la feuille de choix affiche un message
  « Aucun pack d'abonnement actif pour le moment » quand aucun pack n'existe. La section
  Abonnements du dashboard fondateur (doublon de la gestion des packs et des demandes à
  valider) a été retirée. Les clés `platform_settings` legacy
  (`delivery_client_subscription_price`, `delivery_shipper_subscription_price`,
  `delivery_subscription_duration_days`) sont supprimées de la base.
- **Cartes d'offres : ville d'arrivée sous l'aéroport** : la carte d'offre (feed client)
  affiche l'**aéroport d'arrivée** et, en dessous, la **ville d'arrivée**. Le départ
  conserve le pays/origine.

### Version 1.1.8

- **Version de l'app alignée sur le dernier tag GitHub** : `pubspec.yaml` passée
  à `1.1.8+228` (versionName `1.1.8`, versionCode `228` = nombre total de commits),
  cohérente avec ce que la CI `release.yml` dérive depuis le dernier tag `v1.0.91`
  (17 commits depuis → INC 108 → `1.1.8`). La CI écrase de toute façon la valeur
  locale via `--build-name/--build-number`, mais la version source reste cohérente.

### Version 1.1.5

- **Réinitialisation complète de la plateforme** : la fonction `admin_reset_tables`
  vide désormais **toutes les 48 tables** public (ajout des tables récentes :
  abonnements, packs, dépôts, feedbacks, conversations/messages, publicités,
  parrainages, demandes de suppression, etc.) + **tous les buckets Storage**
  (ads, bookings, documents, feedbacks, profiles — purgés récursivement par la
  fonction Edge `admin-reset`).
- **Suppression totale des comptes** : la réinitialisation des comptes liste et
  supprime TOUS les comptes Firebase Auth (via `accounts:query` — énumération
  fiable et complète, sans comptes oubliés) **et** tous les comptes Supabase Auth
  (suppression un par un via l'API admin), puis **vérifie** que les deux sont vides
  (`firebaseAuthEmptied` / `supabaseAuthEmptied` renvoyés dans la réponse).
- **Changement d'abonnement accessible partout** : un utilisateur déjà abonné
  (statut actif ou en attente) peut changer de pack depuis le tableau de bord
  expéditeur, l'accueil client et le profil — avec validation du fondateur.
- **Fiabilité des packs** : rechargement forcé des packs à chaque ouverture du
  sélecteur ; les erreurs de chargement sont désormais affichées avec un bouton
  « Réessayer » au lieu d'un écran vide silencieux.
- **Icône feedback pour tous les rôles** : présents dans les AppBars (y compris
  super_admin), retrait du FAB global.

### Version 1.0.101

- **Nettoyage code mort** : suppression de `_SubscriptionActivationSheet`
  (ancien sheet abonnement client prix fixe, remplacé par
  `SubscriptionPackSheet`) et `_buildRoleFilter` (fonction non référencée).

### Version 1.0.99

- **Workflow abonnement corrigé** : le client utilise maintenant les packs
  configurés par le fondateur (plus le prix fixe ancien).
- **FAB feedback restaurée** : le bouton flottant global est conservé, avec
  en plus un icône dans l'AppBar de tous les écrans (sauf super_admin).
- **Erreurs d'abonnement gérées** : les écrans delivery_request et my_orders
  affichent un dialogue avec bouton « S'abonner » au lieu d'un dead-end.
- **Dashboard expéditeur** : le statut « Validation en attente » s'affiche
  quand un abonnement pending existe (plus caché silencieusement).

### Version 1.0.97

- **Bouton feedback dans l'AppBar** : le FAB global a été remplacé par un
  icône `feedback_outlined` dans l'AppBar de tous les écrans (sauf super_admin).
  Utilisable par tous les rôles pour envoyer un feedback au fondateur.
- **Changement/upgrade d'abonnement** : les utilisateurs avec un abonnement
  actif ou en attente peuvent maintenant changer de pack à tout moment.
  Le bandeau d'abonnement affiche un bouton « Changer » (icône `swap_horiz`).
  Une nouvelle demande est créée et doit être validée par le fondateur.

### Version 1.0.80

- **Badge premium sur l'avatar** : un cercle vert avec icône `verified`
  apparaît en overlay sur la photo de profil quand l'abonnement est actif.
- **Bandeau d'abonnement dans le profil** : le bandeau (statut, type de
  pack, jours restants) est maintenant affiché uniquement dans l'écran
  Profil, sous les badges de rôle (client/expéditeur) et chips.

### Version 1.0.79

- **Optimisation des performances** :
  - `payPlatformFees` : les mises à jour des commissions en attente sont
    maintenant groupées via `.inFilter` (1 requête au lieu de N) avec
    `Future.wait` pour les remises variables.
  - Analytics fondateur : bookings et payments sont fetchés en parallèle
    via un provider combiné (`founderAnalyticsDataProvider`) — 1 round-trip
    réseau au lieu de 2 séquentiels.
  - Écran d'accueil client : le calcul du portefeuille (`wallet`) réutilise
    le même fetch que la liste de suivi — 1 seul appel `getClientBookings`
    au lieu de 2.

### Version 1.0.78

- **Système d'abonnement par packs** : le fondateur crée des packs
  d'abonnement (nom, durée, prix, rôle) via une nouvelle page dédiée dans
  l'admin. Les clients et expéditeurs choisissent un pack dans une feuille
  partagée — le fondateur valide après réception du paiement.
- **Bandeau d'abonnement** : un badge visible en haut de chaque onglet
  affiche le type de pack, le statut (actif / en attente / expiré) et le
  nombre de jours restants.
- **Verrou DeliveryBrowseScreen** : les expéditeurs sans abonnement actif
  ne peuvent plus consulter ni répondre aux demandes de livraison.
- **Drapeaux pays** (`country_flags`) dans le sélecteur d'aéroport, les
  cartes d'aéroport et les tuiles de recherche — origine/destination
  illustrées visuellement par le drapeau du pays.
- **Aéroport d'arrivée obligatoire** : la publication d'un shipment
  nécessite désormais un aéroport de départ ET un aéroport d'arrivée.
- **Offres terminées masquées** : les offres dont la date d'arrivée est
  passée n'apparaissent plus dans les listes actives.
- **Audit Supabase complet** : 43 tables, 5 buckets et toutes les
  politiques RLS vérifiées et alignées avec le code.

### Version 1.0.77

- **Fiabilisation de l'affichage des modèles** : complétion des champs
  manquants côté Dart (horodatage de mise à jour de la grille tarifaire
  `ad_pricing`, identifiants parrain/commande des gains `referral_earnings`
  et du lot `referral_batches`).
- **Stabilité de décodage** : lecture tolérante des dates `created_at` /
  `updated_at` des demandes de livraison, propositions, garanties et
  abonnements (aucun plantage si une date est absente).
- **Correction d'un avertissement d'affichage** dans les feuilles
  « Date limite » de la demande de livraison (l'effet de pression sur la
  ligne du calendrier n'était pas visible) — enrobage `Material`.

### Version 1.0.76

- **Filtre par type d'expéditeur côté serveur (admin/fondateur)** : la liste
  des utilisateurs se filtre désormais directement dans la base PostgREST
  (`inFilter` sur la table `users` après résolution des expéditeurs du type,
  filtre par rôle ajouté) au lieu de charger toute la table en mémoire.
  Pagination correcte, plus de coupe à 500 comptes.
- **Abonnements côté client complétés** : l'achat d'un abonnement
  « Demande de livraison » affiche désormais un état **« Validation en
  attente »** quand le fondateur ne l'a pas encore approuvé (au lieu de
  relancer l'achat), avec le libellé correct après soumission. Le provider
  renvoie l'abonnement actif OU en attente.
- **Écran Finance détaillé par type d'expéditeur (fondateur)** : nouvel écran
  `ShipperTypeFinanceScreen` — synthèse (CA encaissé, commissions réglées,
  commissions dues, CA/expéditeur, effectifs actifs 30 j, commandes en
  attente, top route) puis liste de chaque expéditeur du type avec ses
  chiffres, cliquable vers son profil public. Accessible depuis les cartes
  « Voyageurs ordinaires » / « Micro-Importateurs » du dashboard fondateur.
- **Fix `showDatePicker` (No MaterialLocalizations)** : ajout de
  `flutter_localizations` + `localizationsDelegates` /
  `supportedLocales` avec locale `fr` sur le `MaterialApp` — le sélecteur
  de date (deadline des demandes de livraison) ne plante plus.

### Version 1.0.75

- **Billet QR et numéro de suivi masqués tant que l'expéditeur n'a pas
  accepté la commande** : avant l'acceptation (statut `accepted`), le client
  ne voit plus ni le numéro de suivi ni le QR — seule une puce « Commande en
  attente d'acceptation » s'affiche. Dès que l'expéditeur vérifie et accepte
  le colis, le billet QR et le suivi deviennent accessibles.
- **Chips de statut d'acceptation** : chaque commande client affiche
  désormais « Commande en attente d'acceptation » (ambre), « Commande
  acceptée — attente de collecte » (vert) ou « Refusée : <motif> » (rouge)
  selon l'état — commun aux accueils, commandes, colis et wizard de réservation.
- **Notifications à chaque étape du cycle** : le client est notifié (push +
  in-app) à l'acceptation — « votre billet QR et votre suivi sont
  disponibles » — et au refus avec le motif de l'expéditeur. Les étapes
  confirmé / collecté / envoyé / arrivé / remis au courrier / livré étaient
  déjà notifiées.
- **« Commandes reçues » en tête du tableau de bord expéditeur** : le fil
  des commandes reçues passe au-dessus des statistiques pour un accès
  immédiat, avec toujours les pastilles « en attente » et le bouton Historique.
- **Liste des utilisateurs (admin) robuste** : le chargement des utilisateurs
  pour les envois devient paginé (lecture de toutes les pages par blocs de
  100) — plus de coupe à 500 comptes.
- **Liens « Désactiver le compte » / « Supprimer le compte » retirés du bas
  du profil** (ils restent dans « Gérer mon compte »).

### Version 1.0.74

- **Dashboard Fondateur enrichi** : la carte « Programme de parrainage » est
  désormais affichée en haut du tableau de bord. Les cartes « Voyageurs
  ordinaires » et « Micro-Importateurs » affichent plus de données
  financières (CA/expéditeur, effectifs actifs sur 30 j, commandes en
  attente, route la plus fréquentée).
- **Abonnements « Demande de livraison » avec validation Fondateur** :
  l'achat d'un abonnement (client ou expéditeur) passe désormais par un
  statut « en attente » que le Fondateur doit approuver ou rejeter. Un
  bandeau d'activation apparaît sur le tableau de bord expéditeur, et un
  écran dédié listant les demandes (en attente / actifs / archives) avec
  boutons Approuver / Rejeter a été ajouté au dashboard Fondateur.
- **Commande en cours enrichie (expéditeur)** : la carte « Commandes en
  cours » détaille désormais le nombre de commandes, la répartition par
  statut (en attente, confirmées, en transit), le montant total des
  commandes actives et la prochaine date de départ.
- **Écran « Gérer mon compte »** : déconnexion, désactivation et suppression
  de compte déplacées vers une page dédiée (Zones info, sécurité, données,
  zone dangereuse), accessible depuis le profil.
- **Modèles Dart alignés sur Supabase** : ajout des classes de données
  manquantes (shipper_flags, device_tokens, transfer_tokens,
  delivery_attempts, audit_logs, device_keys, platform_settings,
  referral_codes, etc.).
- **Redesign de l'écran Paramètres plateforme** : sections claires
  (Tarification, Poids, Programme de parrainage, Abonnements), bouton
  d'enregistrement déplacé dans l'en-tête, interface plus lisible.

### Version 1.0.73

- **Fix validation date dans `_ProposalSheet`** : la date proposée par
  l'expéditeur dans une réponse à une demande de livraison est désormais
  initialisée correctement (bornée à la deadline si elle est trop proche),
  le sélecteur de date refusé ouvre/ferme correctement, et une validation
  côté soumission empêche de soumettre une date dépassant la deadline.

### Version 1.0.72

- **Deep link parrainage** : le partage de code parrain génère désormais un
  lien `cargolink://referral/<CODE>` qui ouvre directement l'écran d'inscription
  avec le code pré-rempli et verrouillé. Le nouveau user est automatiquement
  rattaché à son parrain à l'inscription.
- **Formulaire demande client enrichi** : photos en grille de preview avec
  suppression individuelle, bouton caméra (photo instantanée) + galerie
  (multi-sélection, max 8 photos).
- **Abonnement « Demande de livraison »** : card d'activation sur l'accueil
  client avec prix et durée affichés. Le bouton ouvre une feuille de
  confirmation d'achat. Le statut (actif/expiré) s'affiche directement.
- **Dashboard fondateur enrichi** : card « Programme Parrainage » résumé
  cliquable (filleuls, gains payés/en attente), card « Abonnements » avec
  la liste des souscriptions actives, paramètres de prix/durée visibles.
- **FAB Feedback repositionnée** : le bouton flottant de feedback est désormais
  positionné juste au-dessus de la bottom navigation bar pour une meilleure
  accessibilité.
- **Profil nettoyé** : tile « Envoyer un feedback » supprimée (remplacée par
  le FAB). Liens « Désactiver le compte » et « Supprimer le compte » déplacés
  en texte discret tout en bas du profil (style Facebook/Instagram/Snapchat)
  pour éviter les clics accidentels.
- **Sélecteur pays → ville** : nouveau widget `CountryCityPickerField` utilisant
  l'API gratuite `countries.dev` (34 000 villes, sans clé). L'utilisateur choisit
  d'abord un pays, puis une ville de ce pays. Utilisé côté expéditeur (destination)
  et côté client (filtre destination).
- **Aéroport avec ajout manuel** : le sélecteur d'aéroport propose désormais un
  bouton « Ajouter manuellement » quand l'aéroport recherché n'est pas trouvé
  dans la base — l'utilisateur saisit le nom et le code IATA optionnel.
- **Filtres client simplifiés** : l'origine utilise désormais le sélecteur
  d'aéroport (au lieu de la liste statique de pays), la destination utilise le
  sélecteur pays → ville. La feuille `_CityPickerSheet` avec géolocalisation a
  été retirée (fonctionnalité reprise par les nouveaux sélecteurs).
- **Géolocalisation pour filtres destination/origine** : les filtres de
  recherche côté client utilisent désormais un sélecteur de villes avec bouton
  « Me localiser » — trouve automatiquement la ville algérienne la plus proche
  grâce au GPS (formule haversine) et l'affiche avec un badge « Proche » en
  tête de liste.
- **Adresse de collecte géolocalisée** : le champ adresse de collecte côté
  expéditeur dispose d'un bouton de localisation qui remplit automatiquement
  les coordonnées GPS actuelles.
- **Offre à date unique** : la date d'arrivée a été supprimée du formulaire de
  publication d'offre. Chaque offre ne comporte qu'une seule date (départ +
  heure). Un aller-retour = deux offres distinctes.
- **`arrival_date` nullable** : la colonne `arrival_date` en base est désormais
  optionnelle, alignée sur le modèle Dart (`DateTime?`). Les anciennes offres
  avec date d'arrivée continuent de fonctionner normalement.
- **Page web offer.html** : la page de partage d'offre affiche désormais la
  ville de destination (au lieu du code IATA) et la ligne « Arrivée » a été
  supprimée.
- **Suppressions de doublon** : correction du doublon `Constantine` dans les
  coordonnées GPS des villes algériennes.

### Version 1.0.66

- **Onglet « Suivi » (client)** : nouvelle entrée dans la barre de navigation
  inférieure côté client — affiche la liste complète de tous les colis en cours
  avec leur progression (frise de suivi DHL-style). 4 onglets au total :
  Accueil → Suivi → Commandes → Profil.
- **Raccourci header** : le bouton « Mes colis » dans l'en-tête de l'accueil
  client ouvre directement l'onglet Suivi (index 1).

### Version 1.0.65

- **Demande de livraison (premium)** : les clients peuvent publier une demande
  décrivant le produit à expédier (nom, description, photos, poids, ville
  destination, deadline). Les expéditeurs consultent les demandes ouvertes,
  proposent un prix et une date, et le client choisit la meilleure offre.
- **Vérification face-à-face** : une garantie de rencontre physique entre
  client et expéditeur est disponible (photos pièce d'identité + selfie
  des deux parties, confirmation croisée).
- **Abonnement requis** : l'accès à la fonctionnalité « Demande de livraison »
  est payant — le fondateur configure le prix client, expéditeur et la durée
  (en jours) dans Réglages plateforme → Abonnements Demande de Livraison.
- **Navigation intégrée** : carte d'accès direct sur l'accueil client
  (gradient bleu) et dans le tableau de bord expéditeur (après Scanner un colis).
- **Routes nommées** : `/delivery-requests` (client) et `/delivery-browse`
  (expéditeur) enregistrées dans le routeur principal.

### Version 1.0.64

- **Badge Parrain** : un badge doré étoilé s'affiche sur l'avatar de tous
  les utilisateurs qui sont parrains actifs (au moins 1 filleul inscrit).
- **Commission parrainage configurable** : le fondateur règle le pourcentage
  de la commission plateforme reversé au parrain (ex : 50%) dans
  Réglages plateforme → Programme de parrainage. La valeur est lue côté
  serveur par le trigger SQL.
- **Demande de paiement parrain** : le parrain peut demander le paiement
  de ses gains en attente depuis l'écran Parrainage → le fondateur reçoit
  une notification.
- **Suivi colis des filleuls** : le service `getFilleulBookings` récupère
  les réservations en cours de chaque filleul en lecture seule pour le parrain.
- **Texte dynamique** : la section « Comment ça marche » affiche le vrai
  pourcentage de commission (au lieu de 50% en dur).
- **Bénéfice net** : les dûs ne sont déduits du profit qu'à la livraison
  du colis (et non plus au paiement client).

---

## Contenu de cette version (nouveautés Play Store / fonctionnalités)

### Version 1.0.62

- **Tarifs publicitaires : durées hors grille paramétrables** : dans
  Réglages plateforme → « Tarifs publicitaires », le fondateur définit un
  **prix fixe** et un **prix variable par jour** appliqués quand un
  micro-importateur choisit une durée libre absente de la grille
  (Prix = fixe + variable × jours, arrondi au dinar supérieur).
  Les deux champs à 0 conservent l'interpolation automatique historique.
- **Calcul serveur aligné (infalsifiable)** : le trigger SQL qui recalcule le
  prix à la soumission d'une pub lit ces deux réglages (`platform_settings`) —
  l'aperçu prix en direct du formulaire expéditeur utilise exactement la même
  formule.

---

## Contenu de cette version (nouveautés Play Store / fonctionnalités)

### Version 1.0.61

- **Bénéfice net expéditeur corrigé (commissions différées)** : le « Profit net »
  (carte Portefeuille du dashboard) et le « Bénéfice net » (écran Finance) ne
  déduisent plus les dûs plateforme des commandes dont le client n'a pas encore
  payé. La commission n'est comptabilisée en charge que lorsque l'expéditeur a
  réellement encaissé le règlement client (paiement à la livraison reçu).
- **Transparence** : quand des commissions sont différées, l'écran Finance
  affiche la mention « + X [devise] de commission seront déduits quand les
  clients régleront leurs colis ». La liste « Dûs plateforme » et le bouton
  « Payer mes dûs » restent inchangés (toutes les commissions dues y figurent).

---

## Contenu de cette version (nouveautés Play Store / fonctionnalités)

### Version 1.0.58

- **FAB feedback repositionnée** : au-dessus de la bottom navigation bar
  (bottom: 88) pour ne plus la masquer.
- **Texte du formulaire feedback en blanc** : `FeedbackThemeData.dark`
  personnalisé avec `bottomSheetDescriptionStyle` et
  `bottomSheetTextInputStyle` en blanc, fond sombre `#1E1E2E`.
- **ReferralBatch enrichi** : champs `reviewed_by` / `reviewed_at` ajoutés
  au modèle Dart + migration DB同步。
- **5 RPCs V2 créés dans Supabase** (migration `v2_custody_and_payout_rpcs`) :
  `create_transfer`, `accept_transfer`, `complete_transfer`,
  `freeze_payout`, `release_payout` — SECURITY DEFINER, search_path fixé,
  idempotents, accès anon révoqué.
- **Sécurité DB** : `get_public_offer_for_share` reçoit
  `SET search_path = public` (correction advisory).

---

## Contenu de cette version (nouveautés Play Store / fonctionnalités)

### Version 1.0.28

- **Fix rejet Play Store (app loading / 2ème rejet)** : timeout 20s sur
  l'échange de token Supabase (sign-out automatique si échec), FCM init
  timeout 8s, `_GateRoleDecider` max 15 retries + écran d'erreur avec
  bouton « Réessayer », `LoadingScreen` timeout 30s avec bouton retry.
- **Fix rejet Play Store (edge-to-edge)** : `WindowCompat.setDecorFitsSystemWindows`
  dans `MainActivity.kt` + suppression des APIs obsolètes `setStatusBarColor`/
  `setNavigationBarColor`/`immersiveSticky` + suppression `windowFullscreen`
  des 4 fichiers styles.xml — compatible Android 15+.
- **Fix rejet Play Store (UCropActivity)** : suppression de
  `android:screenOrientation="portrait"` sur l'activité UCrop (cassait la
  rotation et pouvait causer des crashes).
- **Sélecteur d'heure publication** : les expéditeurs choisissent désormais
  l'heure de départ ET d'arrivée (via `showTimePicker`) lors de la
  publication d'une offre.
- **Fix sélection users broadcast** : la liste des utilisateurs se charge
  correctement au premier clic (invalidation + await du provider au lieu
  d'un simple `read` qui pouvait renvoyer `null` pendant le chargement).

### Version 1.0.27

- **Programme de parrainage** : un utilisateur génère un code de parrainage
  unique et le partage (WhatsApp, Telegram, SMS) ; un filleul entre ce code
  à l'inscription. Le parrain gagne **50 % de la commission plateforme** sur
  les commandes du filleul. Tableau de bord fondateur pour valider les lots,
  marquer les gains comme payés et superviser les parrains actifs.
- **Bouton Feedback global (FAB)** : un bouton flottant « Avis / Suggestion »
  est visible sur **tous les écrans de tous les rôles** — envoie directement
  un message au fondateur via Supabase.
- **Partage social d'offre** : chaque offre peut être partagée via WhatsApp,
  Telegram ou n'importe quelle app. Le partage génère une **image billet
  d'avion** (style billet de vol CargoLink avec route, dates, prix) et un
  **deep link** `cargolink://offer/<id>` pour ouverture directe dans l'app.
- **Écran détail offre** : en appuyant sur une offre, le client accède à un
  écran dédié avec le billet visuel, la disponibilité, la description de
  l'expéditeur et un bouton « Réserver cette offre ».
- **WorkflowSlider amélioré** : le carrousel « Comment ça marche » est
  désormais scrollable et tolère les contenus longs sur tous les écrans.
- **SafeArea bottom-only universel** : tous les écrans, dialogs et bottom
  sheets n'appliquent le SafeArea qu'en bas (pas de marge inutile en haut).
- **Annonce pub taille cohérente** : toutes les bannières publi (carrousel,
  formulaires, aperçu admin) utilisent un ratio **2:1 (1200×600 px)** et
  affichent la taille idéale pour guider les annonceurs.
- **Filtre destination corrigé** : le filtre par ville côté serveur utilise
  désormais des wildcards `LIKE` pour correspondre correctement aux libellés
  d'aéroports stockés (ex. « Alger » matche « Aéroport d'Alger Houari
  Boumediene (ALG) »).
- **Correction du crash _Notch** dans le billet d'offre (marge négative
  interdite remplacée par Transform.translate).
- **Cleanup code** : suppression de `_buildRoute` mort, migration
  `withOpacity()` → `withValues(alpha:)`, modernisation `super.key`.

### Version 1.0.26

- **Correction de l'échec d'inscription micro-importateur (InvalidKey 400)** :
  les noms de fichiers avec accents, espaces ou parenthèses choisis via le
  sélecteur Windows (ex. « scaled_télécharger (3).jfif ») sont désormais
  assainis côté service avant l'envoi vers Supabase Storage — la clé générée
  est toujours ASCII sûre (horodatage + nom nettoyé + extension).
- **Carrousel des publicités** : sur les accueils client et expéditeur, toutes
  les pubs actives publiées défilent dans un bandeau (défilement automatique
  toutes les 4 s, points indicateurs, clic = ouverture du lien de la pub
  affichée) au lieu d'une seule bannière fixe.
- **Correction du crash « Null check operator »** sur l'accueil client quand
  aucune pub n'est active (le bandeau ne s'affiche que s'il y a des pubs).
- **Barres supérieures flottantes** : les headers compacts se cachent quand on
  fait défiler le contenu vers le bas et réapparaissent dès qu'on remonte.
- **Splash natif régénéré** depuis la nouvelle version du visuel
  `assets/icons/splash3.jpeg` : images Android (classique + Android 12+,
  mode sombre inclus), iOS et web mises à jour.
- **Headers compacts partout (sauf profils)** : le grand header dégradé
  extensible est désormais réservé aux écrans de profil (client, expéditeur,
  profils publics). Tous les autres écrans — accueils, dashboards, listes,
  formulaires, réglages — utilisent une barre supérieure fine et épinglée
  (titre + sous-titre sur une ligne, icône, actions conservées) :
  l'espace d'affichage gagné profite au contenu utile sur tous les écrans.
- **Bannière publicitaire compacte** : sur les accueils client et expéditeur,
  la pub sponsorisée devient un bandeau fixe de 140 px juste sous la barre
  « CargoLink » (épinglé avec elle) au lieu du header plein écran — le
  contenu démarre immédiatement, la pub reste cliquable.
- **Rappel — cloisonnement des pubs expéditeur** : chaque micro-importateur
  ne voit dans « Mes publicités » que ses propres pubs (en attente, en ligne
  ou refusées) ; les bannières actives restent diffusées aux clients et aux
  expéditeurs sur les accueils.
- **Durée d'affichage libre pour les publicités** : le micro-importateur (et le
  fondateur) saisissent n'importe quelle durée de 1 à 365 jours — plus de
  paliers imposés. Des raccourcis (puces des durées configurées) restent
  disponibles. Le prix suit la **courbe tarifaire du fondateur** : palier
  exact si la durée correspond, sinon interpolation linéaire entre les deux
  paliers encadrants, sinon prorata du premier/dernier palier — calcul
  identique côté serveur (infalsifiable, arrondi au dinar supérieur) et
  affiché en direct dans le formulaire.
- **Aéroports de départ et d'arrivée au choix** : le formulaire de publication
  d'une offre propose désormais une **recherche mondiale d'aéroports** (base
  airport-data) — recherche par ville, nom ou code IATA avec drapeau du pays ;
  fini les listes figées, le champ stocke « Aéroport (IATA) ».
- **Photo de profil dans la barre du bas** : l'onglet « Profil » affiche la
  photo de l'utilisateur (icône par défaut sinon) avec bordure quand il est
  actif. Les **expéditeurs** voient en plus une **pastille d'état du dossier**
  (vert = vérifié, orange = en attente, rouge = refusé) directement sur la
  barre de navigation.
- **Tarifs publicitaires paramétrables par le fondateur** : nouvelle section
  « Tarifs publicitaires » dans Réglages plateforme — ajout/suppression libre
  des durées d'affichage et **un prix par durée ET par cible** (Tous /
  Clients / Expéditeurs). Le serveur recalcule toujours le prix depuis cette
  grille (infalsifiable), et le micro-importateur voit le prix changer en
  direct selon la durée et la cible choisies dans son formulaire.
- **Mes publicités : uniquement les siennes** : garde-fou supplémentaire côté
  app — un micro-importateur ne voit que ses propres publicités (en attente,
  en ligne ou refusées), jamais celles des autres.
- **Splash natif régénéré** depuis le nouveau visuel `assets/icons/splash3.jpeg`
  : images Android (classique + Android 12+, mode sombre inclus), iOS et web
  mises à jour.
- **Splash natif régénéré** depuis le nouveau visuel `assets/icons/splash2.png`
  : images Android (classique + Android 12+, mode sombre inclus), iOS et web
  mises à jour.
- **Version de l'app alignée sur les tags CI** : le pied de page du profil
  affiche désormais « CargoLink v1.0.19 (152) » — versionName + versionCode
  identiques aux tags GitHub Releases. `pubspec.yaml` suit le dernier tag
  publié (les builds signés CI écrasent toujours avec la valeur du tag via
  `--build-name/--build-number`) ; le build web reçoit aussi ces flags et son
  `version.json` utilise la bonne clé (`build_number`) pour package_info_plus.
- **Durée d'affichage au choix avec prix en direct** : lors de la soumission
  d'une publicité, le micro-importateur choisit la période d'affichage —
  7 jours (2 000 DZD), 15 jours (3 500 DZD) ou 30 jours (6 000 DZD) — et voit
  le total à payer se mettre à jour instantanément. Le prix est recalculé côté
  serveur selon la durée (impossible de falsifier). Le fondateur choisit aussi
  la durée de ses pubs (sans frais).
- **Expiration automatique** : chaque pub activée reçoit une date d'expiration
  (activation + durée choisie) ; une fois la période dépassée, la bannière
  disparaît automatiquement des écrans d'accueil. L'expéditeur voit « Expire
  le JJ/MM » sur ses pubs en ligne et l'admin voit les pubs hors période.
- **Publicités réservées aux micro-importateurs** : le bouton « Publier une
  publicité » du tableau de bord et le formulaire de soumission ne sont
  accessibles qu'aux comptes micro-importateurs (verrou aussi appliqué côté
  base : RLS + trigger qui refusent toute soumission d'un autre expéditeur).
  Les non-micro voient une notice expliquant comment devenir micro-importateur.
- **Carte « Publicités à valider » (admin & fondateur)** : les dashboards
  affichent désormais le nombre de pubs expéditeurs à traiter. En entrant :
  file « À traiter » (validations + paiements déclarés à confirmer), visualisation
  de la bannière en grand format (zoom plein écran), boutons Approuver /
  Refuser / Confirmer paiement. Le menu fondateur porte aussi le badge.
- **Mes publicités groupées par statut** : l'expéditeur voit ses pubs en trois
  sections — En ligne, En attente (validation ou paiement), Refusées — avec
  compteurs.
- **Détails de l'image avant publication** : dans le formulaire (expéditeur ET
  fondateur), après choix de la bannière, affichage des dimensions en pixels,
  du poids du fichier (Ko/Mo) et du nom, plus un conseil (16:9, < 2 Mo).
- **Fondateur sans validation** : rappel affiché dans son formulaire — ses
  publicités sont mises en ligne immédiatement (il n'a pas besoin
  d'approbation) ; il conserve la liste complète des pubs avec filtre
  « À traiter / Toutes ».
- **Dossier rejeté : l'expéditeur reprend la main** : bannière « Dossier
  rejeté » avec motif dans l'inscription expéditeur et sur l'écran de rôle ;
  il peut basculer entre voyageur ordinaire ↔ micro-importateur puis renvoyer
  le dossier, qui repasse automatiquement **en attente de validation des
  admins/super admins**.
- **Bouton « Publier une publicité » bien visible** : une grande carte dédiée
  (icône 📣) apparaît sur le tableau de bord de l'expéditeur — notamment les
  micro-importateurs — sous « Scanner un colis ». Un appui ouvre la soumission
  de publicité, qui passe par la validation d'un admin/super admin puis le
  règlement des frais avant publication.
- **Régie publicitaire complète** : le fondateur crée des pubs façon Facebook
  Ads depuis « Publicités » — image paysage, titre, lien de destination et
  **audience au choix (Tous / Clients / Expéditeurs)** avec aperçu en direct ;
  la bannière cliquable s'affiche en haut de l'accueil ciblé et ouvre le lien.
- **Publicités expéditeur avec validation et paiement** : un expéditeur soumet
  sa pub (« Mes publicités », icône 📣 du tableau de bord) ; après
  **acceptation par un admin/super admin**, il déclare le paiement des frais de
  publication (2000 DZD), l'admin confirme, la pub passe **en ligne**. Suivi de
  statut complet côté expéditeur (validation en cours, paiement requis,
  paiement déclaré, en ligne, refusée + motif).
- **Session qui n'expire plus (PGRST303)** : le JWT Supabase échangé contre le
  compte Firebase est maintenant **renouvelé automatiquement** avant expiration
  (décodage de la date d'exp, rafraîchissement partagé à 2 min du seuil), fini
  les erreurs « JWT expired » au bout d'une heure.
- **Photos KYC agrandissables (admin & fondateur)** : dans les dossiers en
  attente de vérification, chaque photo (passeport, selfie, carte micro-
  importateur — cette dernière désormais affichée) apparaît en **aperçu carré
  1:1** ; un appui ouvre la photo en plein écran avec pincement pour zoomer et
  vérifier l'authenticité. Les photos produit du détail commande fondateur sont
  aussi agrandissables.

### Version 1.0.14

- **Suivi multi-colis sur l'accueil client** : la carte « Suivi de colis »
  affiche désormais **tous les colis pas encore livrés** (et non plus une
  seule commande), chacun avec son avancement en temps réel ; « Voir tout »
  ouvre le nouvel écran **Mes colis** où chaque colis se déplie avec ses
  détails et sa frise de suivi complète.
- **« Commandes en cours » côté expéditeur** : une carte de synthèse sur le
  tableau de bord recense les commandes reçues pas encore livrées ; un appui
  ouvre la liste dédiée avec, pour chaque commande, les détails du dossier,
  la frise de suivi et le billet QR.
- **Billet QR réutilisé partout** : l'icône QR dans les listes de colis
  (client et expéditeur) rouvre le même billet de réservation que dans le
  parcours de réservation.
- **Photos de preuve en caméra arrière** : « Collecter le colis », preuves de
  livraison et photo de la carte micro-importateur ouvrent désormais la
  caméra arrière (le selfie reste en caméra frontale pour l'identité).
- **Portefeuille calculé comme un comptable** : profit net = chiffre
  d'affaires total (encaissé + à recevoir) moins les charges réelles — les
  commissions des commandes annulées et remboursées sont exclues ; la
  trésorerie nette (encaissé − commissions réglées) est aussi disponible.
- **Carte Portefeuille sur les écrans d'accueil** : gros montant principal
  (profit net côté expéditeur, total dépensé côté client), pastille des dus /
  restes à payer, et un appui ouvre les détails financiers ou la liste des
  colis.
- **Changement de type d'expéditeur depuis l'écran de rôle** : un expéditeur
  vérifié peut basculer entre voyageur ordinaire et micro-importateur ;
  passer en micro-importateur demande la photo de la carte, et le dossier est
  renvoyé en vérification administration.
- **Retour à l'accueil facilité** : bouton « Aller à l'accueil » après
  l'envoi du dossier d'inscription expéditeur et quand le dossier est déjà
  vérifié.
- **Affichage confortable sur tous les écrans** : SafeArea généralisée sur
  les écrans principaux (client, expéditeur, admin) pour respecter les
  encoches et les barres système.

---

### Version 1.0.12

- **Splash et icônes : retour à la normale** : l'essai de nouvelle génération
  publié en v1.0.11 déformait l'icône de l'app et l'écran de démarrage — la
  configuration d'origine est rétablie (même icône, même splash plein écran
  qu'en v1.0.10, générés par flutter_native_splash + flutter_launcher_icons).
- **Favicon et icônes PWA web aux couleurs de la marque** : favicon et icônes
  web remplacés par le logo CargoLink, manifest web aux couleurs indigo.
- **Preview caméra selfie corrigée** : l'aperçu de la caméra dans
  l'enregistrement vidéo n'est plus déformé (étiré en largeur) en mode
  portrait — le ratio capteur est inversé automatiquement.
- **Pied de page profil** : la version exacte de l'app (ex. « CargoLink
  v1.0.11 ») et la mention « Développé par FORSLOG ltd » s'affichent en bas
  du profil, pour tous les rôles.
- **Durcissement sécurité côté base** : politiques RLS restreintes aux
  utilisateurs connectés, fonctions trigger isolées (search_path figé,
  exécution retirée au public), index ajoutés sur toutes les clés
  étrangères, doublons d'index supprimés.

- **Réception confirmée = « Livré avec succès » partout** : quand le client
  confirme la réception (scan QR, saisie du code de suivi ou bouton dans
  l'écran de suivi), un événement « Livré avec succès — réception confirmée
  par le client » est ajouté à la frise, la timeline passe en validation
  verte et une bannière verte « Livré avec succès » s'affiche sur l'écran de
  suivi.
- **Carte « Suivi de colis » sur l'accueil client** : sous la salutation, une
  carte affiche la commande en cours (ou la dernière livrée) — produit,
  numéro de suivi, étape actuelle, barre de progression et badge vert
  « Livré avec succès ». Un appui ouvre le suivi détaillé.
- **Type d'expéditeur sur le profil et les listes admin/fondateur** : le badge
  « Voyageur ordinaire » / « Micro-Importateur » apparaît désormais sous le
  badge de rôle sur le profil expéditeur, sur chaque carte de la grille
  utilisateurs (admin/fondateur) et dans le détail utilisateur (badge + ligne
  « Type » du dossier expéditeur).
- **Dashboard fondateur : répartition par type d'expéditeur** : deux cartes
  « Voyageurs ordinaires » et « Micro-Importateurs » avec l'effectif, le CA
  encaissé, les commissions réglées et les commissions restant dues pour
  chaque type.
- **Erreur 23514 au flux de vérification corrigée** : la contrainte CHECK de
  `shipment_tracking` accepte maintenant les événements `verified` et
  `verification_returned` émis lors de la vérification du colis (poids,
  articles) et de son renvoi éventuel.
- **Commandes annulées épurées (dashboard expéditeur)** : une commande annulée
  n'affiche plus les puces « Paiement en attente » ni « En attente de
  confirmation » — le badge « Annulée » de l'en-tête suffit.
- **QR de réservation ré-enregistrable** : nouveau bouton « QR » sur chaque
  commande client — réaffiche le billet et réenregistre **le même code QR**
  généré à la création (jamais régénéré) dans la galerie (PNG sur web).
- **Refus de commande redessiné** : feuille modale avec motifs rapides
  (articles interdits, poids, emballage, client injoignable, paiement, place)
  + champ libre, au lieu d'une boîte de dialogue brute.
- **Confirmation de commande enrichie** : le client reçoit la notification et
  sa frise de suivi affiche immédiatement « Commande confirmée — en attente de
  collecte du colis ou marchandises » à la place de « Paiement en attente ».
- **Type d'expéditeur visible partout** : badge « Voyageur ordinaire » ou
  « Micro-Importateur » sur les cartes d'offres, profils public, écran de suivi,
  commandes client et statut du profil.
- **Poids disponible toujours exact dans la réservation** : resynchronisation à
  l'ouverture + toutes les 10 s en plus du temps réel — impossible de réserver
  sur un poids périmé.
- **Adresse de livraison obligatoire** : validée dans le wizard ET côté service
  (l'écran de réservation historique a aussi son champ adresse).
- **Offres masquées si le compte expéditeur est désactivé** (RLS) : les offres
  actives d'un compte désactivé disparaissent du fil client ; les clients ayant
  déjà une réservation conservent l'accès au suivi. Réactivation = offres de
  nouveau visibles ; suppression définitive après 30 jours via la fonction
  `delete-account` existante.
- **Dashboard expéditeur temps réel renforcé** : les cartes de statistiques et
  la liste des commandes se mettent à jour à chaque événement, et tout est
  rechargé au retour sur l'onglet (filet de sécurité si un événement est manqué).
- **Erreurs `AuthException` corrigées** : les services (annulation de commande,
  publicités) n'accèdent plus à `supabase.auth` (interdit avec l'option
  `accessToken`) mais passent par l'identifiant déterministe `AuthService`.

- **Règle Visa -30 % assouplie** : seules les offres dont l'expéditeur a coché
  « Payer par carte Visa (-30 %) » passent en attente de confirmation du
  fondateur ; toutes les autres sont **publiées immédiatement** et visibles des
  clients (dû marqué payé, échéance de régularisation à 7 jours). La recherche
  client n'affiche plus que les offres au dû réglé ou confirmé.
- **Portefeuille fondateur** : nouvelle section « Portefeuille » du dashboard —
  totaux multi-devises (DZD, EUR, USD, RMB…), filtres À payer / Payés /
  Remboursés, actions « Confirmer » et « Rembourser » sur chaque dû.
- **Portefeuille expéditeur** : cartes « Commission remboursée » et « Dûs payés »,
  statut « Remboursé » affiché sur les dûs concernés, et devise propre à chaque
  dû (plus d'amalgame DZD/EUR/USD).
- **Réservation débloquée** : le bouton d'action du wizard ne reste plus bloqué
  à l'étape paiement — la confirmation (QR) est atteignable.
- **Filtres accueil client corrigés** : les puces « Voyageurs / Micro-importateurs »
  filtrent de nouveau correctement le fil d'offres.
- Plus d'erreur `PGRST116` lors de la confirmation fondateur d'une publication
  (politique UPDATE admin ajoutée côté base).

- **Workflow complet de livraison en 7 phases** (du dépôt du colis à la remise finale) :
  - **Type d'expéditeur voyageur / micro-importateur** : à l'inscription, l'expéditeur
    choisit son type ; un micro-importateur doit fournir sa **carte de commerce**
    (photo) pour être vérifié. Un **badge « Micro-importateur »** apparaît partout
    (cartes d'offres, profil public, dashboard, écran expéditeur, filtres) et des
    **filtres « Voyageurs / Micro-importateurs »** trient l'accueil client.
  - **Confirmation fondateur des publications** : chaque offre publiée par un
    expéditeur déclenche un **dû de publication** (commission de publication). Tant
    que le fondateur n'a pas confirmé le paiement, **l'offre reste cachée des
    clients** (badge « Validation en attente » côté expéditeur). Paiement par carte
    Visa = -30 % de remise (passage en « attente de confirmation ») ; le fondateur
    confirme depuis son dashboard.
  - **Réservation enrichie (client)** : le client renseigne son **téléphone, adresse
    de livraison et une photo de sa pièce d'identité (CNI)** avant d'envoyer sa
    commande.
  - **Refus avec motif** : l'expéditeur peut refuser une commande avec une raison ;
    une bannière dédiée s'affiche chez le client avec le motif.
  - **Réception physique + vérification** : à la collecte, l'expéditeur prend une
    **photo du colis** ; il lance ensuite la **vérification** (feuille de vérification
    : liste d'articles interdits + poids réel). Si un article est interdit ou le poids
    différent, le colis est **renvoyé au client** qui doit corriger avant un second
    essai.
  - **Livraison finale** : à l'arrivée, l'expéditeur valide la **géolocalisation**
    (repli sur la ville de destination si le GPS est indisponible). Il choisit de
    **déposer le colis chez un courrier local** (nom + code de suivi, partagés au
    client) ou de le **remettre en main propre** au client en **scannant son QR code**
    de collecte (client notifié instantanément).
  - **Dûs plateforme (échéance 7 jours)** : l'écran Finance de l'expéditeur liste ses
    **dûs** (montant, échéance à 7 jours, indicateur « En retard » passé le délai).
    Paiement par **Baridimob/virement** ou **carte Visa (-30 %)** ; après la demande,
    le fondateur confirme le règlement. Passé l'échéance, le fondateur peut
    **transmettre le dossier à la justice** (statut visible des deux côtés).
- **Liste des commandes client mise à jour instantanément (définitif)** : le pager
  « Mes Commandes » du client appelle directement le service (`getClientBookings`)
  à chaque rechargement — onglet ré-entré, changement de filtre ou événement
  realtime — au lieu d'un `FutureProvider` mis en cache qui renvoyait l'ancien
  résultat. Une commande créée ailleurs (ex. depuis la réservation) apparaît donc
  immédiatement sous « Toutes », comme dans l'Historique du profil.
- **Versioning 1.{MINOR}.{PATCH}** : passage du schéma de numérotation au
  `1.{MINOR}.{PATCH}` (le patch s'incrémente de 0 à 99 puis bascule à 0 en
  incrémentant la mineure) ; `versionCode` = nombre total de commits. Première
  release : `1.0.0`.
- **Système de publicités** : le fondateur ou un admin peut ajouter une publicité
  (image paysage + lien) depuis l'écran « Publicités » du menu fondateur, l'activer
  ou la désactiver, et la supprimer. La bannière s'affiche sur l'accueil des
  clients à la place du header (l'appbar reste intacte) ; toucher l'image ouvre
  le lien dans le navigateur.
- **Avatar cliquable → profil public** : toucher l'avatar d'un utilisateur n'importe
  où (liste de conversations, écran de chat, commandes client, réservations
  expéditeur, listes admin — grille users, tuiles d'offres et de réservations,
  détail d'entité — écran de vérification, transactions, analytics fondateur,
  expéditeurs en attente et sélecteur de diffusion) ouvre son **profil public**
  — profil expéditeur s'il est expéditeur, profil client sinon — avec nom, rôle,
  date d'inscription et coordonnées (téléphone, WhatsApp, Télégram, réseaux).
- **Gestes tuile/avatar séparés** : sur les cartes d'offres (recherche client), les
  commandes client et les réservations du dashboard expéditeur, toucher l'avatar
  ouvre le profil public tandis que toucher la tuile déclenche l'action principale
  (détail de l'offre / suivi) — plus d'ouverture accidentelle du profil.
- **Inscription & connexion fiabilisées** : l'échange de session Firebase → Supabase
  est sérialisé (plus d'échec « Database error creating new user » au premier
  lancement d'un nouveau compte, causé par deux demandes concurrentes) et la
  fonction `auth-exchange-firebase` est devenue idempotente (ré-vérifie le compte
  après une erreur de création).
- **Offres et kg disponibles mis à jour en temps réel** : après la création d'une
  réservation (même sans paiement immédiat), le poids réservé de l'offre se met à
  jour dans le fil de recherche — via le realtime et un rechargement déterministe
  du fil comme filet de sécurité.
- **Finances précises partout** : le chiffre d'affaires d'un expéditeur = commandes
  payées et non annulées (plus besoin d'être livrées) ; le **bénéfice net** = CA
  moins la **commission plateforme totale** (réglée ou non) ; la dette affichée
  = commission restant à payer. Cohérent entre le dashboard, l'écran Finance,
  le profil et le graphique mensuel (filtré sur les commandes payées).
- **Payer la plateforme** : bouton dédié dans le profil expéditeur et l'écran
  de commission (renommé depuis « Payer mes dues ») ; le fondateur reçoit et
  **confirme le paiement** avec le bouton « Paiement confirmé » (anciennement
  « Confirmer »). Les finances se rafraîchissent partout en temps réel après
  le paiement ou la confirmation.
- **« Pas de dettes »** : quand un expéditeur n'a rien à payer, la section
  finance l'affiche explicitement (au lieu d'un montant à zéro) — sur le
  tableau de bord, l'écran Finance, le profil et la vue fondateur.
- **Vue finance par expéditeur (fondateur)** : l'analytics du fondateur liste
  chaque expéditeur avec son CA encaissé, sa commission réglée et sa
  commission due, et détaille les commissions encaissées / en attente de
  confirmation / à encaisser.
- **Accueil expéditeur refondu** : l'appbar ne garde que les actions essentielles
  (notifications, chat, déconnexion) ; un grand bouton « Publier une offre » et une
  grande carte « Scanner un colis » sont affichés en tête de page.
- **Compagnie aérienne sur toutes les cartes d'offres** : le formulaire de publication
  d'une offre comporte un champ « Compagnie aérienne » à côté du numéro de vol, et la
  compagnie apparaît (quand elle est renseignée) sur chaque carte d'offre pour tous les
  rôles : dashboard expéditeur, historique profil, recherche client (ShipperCard),
  profil public expéditeur, suivi colis, ticket QR, scan QR, listes et détail admin.
- **Historique des offres cliquable** : toucher une offre dans l'historique du profil
  expéditeur ouvre son détail.
- **Scanner QR sur desktop** : sur Windows/Linux (sans caméra), l'écran de scan propose
  la saisie manuelle du code au lieu de planter (pas d'implémentation desktop de la caméra).
- **Compagnie aérienne sur les offres expéditeur** : le formulaire de publication
  d'une offre comporte désormais un champ « Compagnie aérienne » à côté du numéro
  de vol, et la compagnie est affichée sur tous les écrans où l'offre apparaît
  (dashboard expéditeur, historique profil, recherche client, suivi colis,
  ticket QR, scan QR, admin) pour tous les rôles.
- **Dates au format « 20 mars 26 »** (jour + mois en toutes lettres + année sur
  2 chiffres) sur le tableau de bord expéditeur — corrige aussi un léger
  dépassement de la ligne des dates.
- **Changement de rôle sans crash** : passer de client à expéditeur (ou l'inverse)
  ne provoque plus d'erreur `BottomNavigationBar` (l'onglet actif est remis à zéro
  et borné au bon nombre d'onglets).
- Plus d'erreur `PGRST116` dans les logs quand l'utilisateur vient de passer
  expéditeur mais n'a pas encore de profil expéditeur (dossier non soumis).
- Plus d'erreur `PGRST108` sur le résumé finance expéditeur (la requête embarque
  désormais la ressource `shipments`).
- **Badge de messages non lus en temps réel** : quand un utilisateur reçoit un message,
  le badge de l'inbox affiche instantanément le nombre exact de messages non lus
  (recalculé à chaque réception, sans action manuelle).
- **Push FCM avec badge de non-lus** : la notification inclut le nombre de messages
  non lus (`notification.badge` sur iOS/macOS + `data.unread_count`) — fonctionne sur
  Android / iOS / macOS (pas de FCM sur desktop/web, limitation Firebase).
- Photo de profil modifiable sur le **web** (plus d'erreur `image_cropper` : upload
  direct des octets via ImagePicker).
- QR code de collecte/réception avec **référence de suivi courte et unique**
  (10 caractères alphanumériques, sans caractères ambigus) — même code QR/suivi.
- **Upload de photos produit avec progression** (spinner au choix + barre de progression).
- **Téléchargement du ticket de confirmation en PNG sur le web** (plus d'échec).
- **SafeArea** appliquée sur tous les écrans scrollables, bottom sheets et dialogs.
- **Boutons déconnexion + suppression de compte** sur « Choisir votre rôle ».
- **Broadcasts + notifications push** à chaque changement de statut.
- Identité de l'app : package `com.cargolink.dz.cargolink`, icône custom, splash plein
  écran, mode immersiveSticky.

---

## Signature de l'application

- **Keystore de signature** : stocké dans les secrets GitHub (jamais commité) :
  `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEYSTORE_KEY_ALIAS`, `KEY_PASSWORD`.
- Le workflow `release.yml` décode le keystore dans la CI et signe **automatiquement**
  le APK et le AAB release à chaque push sur `master` (ou via `workflow_dispatch`).
- **Important Play Console** : conservez le keystore précieusement. Si vous activez
  la signature Play App Signing, Google gère la clé d'application ; la clé de dépôt
  reste le keystore CI. **Sauvegardez-le hors du dépôt** (perte = impossibilité de
  mettre à jour l'app).

---

## Fiche Play Store (listing)

Fichier de référence complet et prêt à copier-coller : `playstore/PLAY_STORE_FICHE.md`

### Brève description (80 caractères max — 74 utilisés)
```
CargoLink : expédiez et suivez vos colis en Algérie, avec livraison sécurisée.
```

### Description complète
Rédigée en français (≤ 4000 caractères), sans promesses irréalistes — points couverts :
suivi en temps réel, notifications push, réseau de dépôts de collecte, offres des
transporteurs, messagerie intégrée, identité vérifiée, paiement flexible.
Source : `docs/playstore_description.md` et section 2 de `PLAY_STORE_FICHE.md`.

### Catégorie & pays
- Catégorie : **Voyages et transports locaux** (ou Affaires → Productivité)
- Pays : **Algérie** au minimum (à élargir selon la stratégie)
- Tranche d'âge : **Adulte (18+)** — contenu familial : **Non**

### Tags suggérés
```
colis, livraison, transport, expédition, Algérie, logistique, suivi de colis, envoi de colis, dépôt de collecte, transporteur
```

---

## Assets générés (dossier `playstore/assets/`)

Générés automatiquement par `tools/generate_playstore_assets.py` :

| Fichier | Usage Play Console | Dimensions |
|---|---|---|
| `app_icon_512.png` | Icône de l'application | 512×512 (fond indigo arrondi) |
| `feature_graphic_1024x500.png` | Bannière en haut de la fiche | 1024×500 |
| `screenshot_home_1080x1920.png` | Capture — suivi des colis | 1080×1920 |
| `screenshot_tracking_1080x1920.png` | Capture — suivi GPS temps réel | 1080×1920 |
| `screenshot_offers_1080x1920.png` | Capture — recherche de transport | 1080×1920 |
| `screenshot_finance_1080x1920.png` | Capture — finances & stats | 1080×1920 |

**⚠️ Note** : les 4 captures sont des **maquettes générées** (textes FR sans accents).
Google exige de vraies captures d'écran de l'app — remplacer par des screenshots
réels avant soumission : `adb exec-out screencap -p > capture.png` ou Power+Volume bas.

---

## Sécurité des données (formulaire Data Safety)

Réponses détaillées prêtes à recopier dans **section 4** de `PLAY_STORE_FICHE.md`.
Résumé :

- **L'app collecte ou partage des données ?** → **OUI**
- **Création de compte** : nom d'utilisateur + mot de passe ☑️, OAuth Google ☑️
- **Types de données collectées/partagées** : nom, e-mail, téléphone, adresse physique,
  autres infos personnelles (réseaux sociaux, photo profil), historique des achats,
  messages in-app, photos (selfie, pièce d'identité, colis), fichiers/documents,
  ID d'appareil (token FCM).
- **NON collecté** : localisation GPS, carte bancaire, crédit, santé, contacts, agenda,
  audio, vidéo, activité in-app, navigation web, données de performance.
- **Chiffrement** : Oui (HTTPS). **Suppression des données** : Oui (suppression de compte
  intégrée). **Finalité** : fonctionnement de l'app + gestion des comptes + communications
  développeur (FCM). **Pas** d'analytics, de pub ni de personnalisation.
- **Aucune fonctionnalité financière** déclarée (paiements hors-ligne : espèces à la
  livraison, virement, CCP).

---

## Politique de confidentialité & suppression de compte

Hébergées sur **GitHub Pages** (déployées automatiquement par le workflow `deploy.yml`
à chaque push sur `master`, via `docs/privacy_policy.html` et `docs/account_deletion.html`) :

| Champ Play Console | URL |
|---|---|
| Politique de confidentialité | https://connacri.github.io/CargoLink/privacy_policy.html |
| Lien de suppression de compte | https://connacri.github.io/CargoLink/account_deletion.html |

Suppression partielle sans supprimer le compte : **Oui** (photo, documents, messages,
colis supprimables dans l'app).

---

## Checklist avant envoi pour examen (à la lettre)

- [ ] Déposer `app-release.aab` (version ci-dessus) en « Test interne » → puis « Test fermé »
- [ ] Description = celle de `PLAY_STORE_FICHE.md` (fidèle aux fonctionnalités réelles)
- [ ] **Remplacer les captures par de vraies captures d'écran** (interdiction des maquettes)
- [ ] Icône + feature graphic depuis `playstore/assets/`
- [ ] Lien suppression de compte renseigné (`account_deletion.html`)
- [ ] Lien politique de confidentialité renseigné (`privacy_policy.html`)
- [ ] Formulaire Data Safety rempli selon la section ci-dessus
- [ ] Chiffrement Oui / Pas d'analytics / Pas de pub
- [ ] Pas de fonctionnalité financière déclarée
- [ ] Tranche d'âge adulte (18+), contenu familial : Non
- [ ] Signature App Signing : téléverser le keystore CI en « clé de dépôt »
- [ ] Vérifier versionCode croissant (106 > 104 du dépôt précédent)

---

## Rappel : versionCode doit toujours augmenter

Le workflow `release.yml` calcule `versionCode = nombre total de commits`. Chaque push
sur `master` produit une nouvelle release avec un versionCode supérieur au précédent,
donc chaque AAB peut être déposé sans risque de « downgrade » rejeté par Play.