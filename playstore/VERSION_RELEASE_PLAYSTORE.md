# VERSION RELEASE PLAYSTORE

> Ce fichier est **mis à jour après chaque commit** : il décrit toujours la version
> courante prête pour la Google Play Console, le build à déposer et tout ce qui a été
> fait pour la Play Store dans cette version.

---

## Dernière version

| Élément | Valeur |
|---|---|
| Version (versionName) | **1.0.13** |
| Code de version (versionCode) | **140** (nombre total de commits — monotone, obligatoirement croissant entre 2 dépôts) |
| Commit de référence | `85beb5e` |
| Statut CI | À publier au prochain push → release `v1.0.13` sur GitHub |
| Type de build | **App Bundle (.aab) signé** — seul format accepté par la Play Console |
| Fichier à déposer | `app-release.aab` (≈ 84 Mo) |
| Origine du fichier | GitHub Release **v1.0.0** → workflow `release.yml` (job `android-aab`) |
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