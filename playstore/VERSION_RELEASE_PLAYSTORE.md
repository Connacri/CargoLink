# VERSION RELEASE PLAYSTORE

> Ce fichier est **mis à jour après chaque commit** : il décrit toujours la version
> courante prête pour la Google Play Console, le build à déposer et tout ce qui a été
> fait pour la Play Store dans cette version.

---

## Dernière version

| Élément | Valeur |
|---|---|
| Version (versionName) | **1.0.28** |
| Code de version (versionCode) | **174** (nombre total de commits — monotone, obligatoirement croissant entre 2 dépôts) |
| Commit de référence | `ac56192` |
| Statut CI | À publier au prochain push → release `v1.0.28` sur GitHub |
| Type de build | **App Bundle (.aab) signé** — seul format accepté par la Play Console |
| Fichier à déposer | `app-release.aab` (≈ 84 Mo) |
| Origine du fichier | GitHub Release **v1.0.28** → workflow `release.yml` (job `android-aab`) |
| Nom du package | `com.cargolink.dz.cargolink` (aligné sur `google-services.json`, nécessaire pour Firebase/push) |
| SDK cible | Android 13 (API 36) compilé dans la CI (`platforms;android-36`) |

**Télécharger le bundle** (remplacer `X.Y.Z` par la version ci-dessus) :
```
https://github.com/Connacri/CargoLink/releases/download/vX.Y.Z/app-release.aab
```

**Canal de test conseillé** : Play Console → « Test interne » d'abord (sécurité),
puis « Test fermé » avec des bêta-testeurs, puis Production.

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