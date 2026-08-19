# Descriptif Play Store Console — Version v0.1.77 (build 90)

> Récapitulatif de tout ce qui a été fait pour la **Google Play Console** pour cette
> version. À utiliser comme référence lors du dépôt du bundle et du remplissage de la fiche.

---

## 1. Build prêt pour la Play Console

| Élément | Valeur |
|---|---|
| Version (versionName) | **0.1.77** |
| Code de version (versionCode) | **90** (nombre total de commits — monotone, obligatoirement croissant entre 2 dépôts) |
| Type de build | **App Bundle (.aab) signé** — seul format accepté par la Play Console |
| Fichier à déposer | `app-release.aab` (≈ 84,4 Mo) |
| Origine du fichier | GitHub Release **v0.1.77** → workflow `release.yml` (job `android-aab`) |
| Nom du package | `com.cargolink.dz.cargolink` (aligné sur `google-services.json`, nécessaire pour Firebase/push) |
| SDK cible | Android 13 (API 36) compilé dans la CI (`platforms;android-36`) |
| Architectures | AAB multi-arch (arm64-v8a, armeabi-v7a, x86_64) — les APK split sont générés par Play |

**Télécharger le bundle** :
```
https://github.com/Connacri/CargoLink/releases/download/v0.1.77/app-release.aab
```

**Canal de test conseillé** : Play Console → « Test interne » d'abord (sécurité),
puis « Test fermé » avec des bêta-testeurs, puis Production.

---

## 2. Signature de l'application

- **Keystore de signature** : stocké dans les secrets GitHub (jamais commité) :
  `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEYSTORE_KEY_ALIAS`, `KEY_PASSWORD`.
- Le workflow `release.yml` décode le keystore dans la CI et signe **automatiquement**
  le APK et le AAB release à chaque push sur `master` (ou via `workflow_dispatch`).
- **Important Play Console** : conservez le keystore précieusement. Si vous activez
  la signature Play App Signing, Google gère la clé d'application ; la clé de dépôt
  reste le keystore CI. **Sauvegardez-le hors du dépôt** (perte = impossibilité de
  mettre à jour l'app).

---

## 3. Fiche Play Store (listing)

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

## 4. Assets générés (dossier `playstore/assets/`)

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

## 5. Sécurité des données (formulaire Data Safety)

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
- **Aucune fonctionnalité financière** déclarée (les paiements sont des modes hors-ligne :
  espèces à la livraison, virement, CCP).

---

## 6. Politique de confidentialité & suppression de compte

Hébergées sur **GitHub Pages** (déployées automatiquement par le workflow `deploy.yml`
à chaque push sur `master`, via `docs/privacy_policy.html` et `docs/account_deletion.html`) :

| Champ Play Console | URL |
|---|---|
| Politique de confidentialité | https://connacri.github.io/CargoLink/privacy_policy.html |
| Lien de suppression de compte | https://connacri.github.io/CargoLink/account_deletion.html |

Suppression partielle sans supprimer le compte : **Oui** (photo, documents, messages,
colis supprimables dans l'app).

---

## 7. Fonctionnalités implémentées dans cette version (pertinentes pour la Play Console)

- **Identité de l'app** : package `com.cargolink.dz.cargolink` restauré/aligné sur
  `google-services.json` → **push notifications Firebase** opérationnelles.
- **Icône custom** + **splash plein écran** (`splash2.png`) + mode **immersiveSticky**.
- **Suppression de compte** en toute conformité : demande validée par le super admin,
  données archivées dans `deleted_accounts`, purge du compte — requis par Google.
- **Bannière APK** sur la version web Android (invite à installer l'APK).
- **QR code** de collecte/réception avec **référence de suivi courte et unique**
  (10 caractères alphanumériques, sans caractères ambigus).
- Notifications push (broadcasts) à chaque changement de statut.

---

## 8. Checklist avant envoi pour examen (à la lettre)

- [ ] Déposer `app-release.aab` (v0.1.77) en « Test interne » → puis « Test fermé »
- [ ] Description = celle de `PLAY_STORE_FICHE.md` (fidèle aux fonctionnalités réelles)
- [ ] **Remplacer les captures par de vraies captures d'écran** (interdiction des maquettes)
- [ ] Icône + feature graphic depuis `playstore/assets/`
- [ ] Lien suppression de compte renseigné (`account_deletion.html`)
- [ ] Lien politique de confidentialité renseigné (`privacy_policy.html`)
- [ ] Formulaire Data Safety rempli selon la section 5
- [ ] Chiffrement Oui / Pas d'analytics / Pas de pub
- [ ] Pas de fonctionnalité financière déclarée
- [ ] Tranche d'âge adulte (18+), contenu familial : Non
- [ ] Signature App Signing : téléverser le keystore CI en « clé de dépôt »
- [ ] Vérifier versionCode croissant (90 > 89 du précédent dépôt)

---

## 9. Rappel : versionCode doit toujours augmenter

Le workflow `release.yml` calcule `versionCode = nombre total de commits`. Chaque push
sur `master` produit une nouvelle release avec un versionCode supérieur au précédent,
donc chaque AAB peut être déposé sans risque de « downgrade » rejeté par Play.