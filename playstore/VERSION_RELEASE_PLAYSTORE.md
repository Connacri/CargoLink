# VERSION RELEASE PLAYSTORE

> Ce fichier est **mis à jour après chaque commit** : il décrit toujours la version
> courante prête pour la Google Play Console, le build à déposer et tout ce qui a été
> fait pour la Play Store dans cette version.

---

## Dernière version

| Élément | Valeur |
|---|---|
| Version (versionName) | **0.1.95** |
| Code de version (versionCode) | **110** (nombre total de commits — monotone, obligatoirement croissant entre 2 dépôts) |
| Commit de référence | `d519d5d` |
| Statut CI | À publier au prochain push → release `v0.1.95` sur GitHub |
| Type de build | **App Bundle (.aab) signé** — seul format accepté par la Play Console |
| Fichier à déposer | `app-release.aab` (≈ 84 Mo) |
| Origine du fichier | GitHub Release **v0.1.95** → workflow `release.yml` (job `android-aab`) |
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

- **Avatar cliquable → profil public** : toucher l'avatar d'un utilisateur n'importe
  où (liste de conversations, écran de chat, commandes client, réservations
  expéditeur, listes admin — grille users, tuiles d'offres et de réservations,
  détail d'entité — écran de vérification, transactions, analytics fondateur,
  expéditeurs en attente et sélecteur de diffusion) ouvre son **profil public**
  — profil expéditeur s'il est expéditeur, profil client sinon — avec nom, rôle,
  date d'inscription et coordonnées (téléphone, WhatsApp, Télégram, réseaux).
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
- **Liste des commandes client** mise à jour instantanément (réel-time + rechargement
  à la ré-entrée de l'onglet, comme l'Historique).
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