# 📱 CargoLink — Fiche Google Play Store (à copier-coller)

> Tout le contenu pour remplir la Play Console. Blocs séparés par des séparateurs `---` pour copier facilement.

---

## 1. Brève description (80 caractères max)

```
CargoLink : expédiez et suivez vos colis en Algérie, avec livraison sécurisée.
```
*(74 caractères, OK)*

---

## 2. Description complète (max 4000 caractères)

```
CargoLink est la plateforme algérienne qui connecte les expéditeurs de colis et les clients, de la réservation à la livraison.

Suivi de colis en temps réel
- Suivez chaque étape de votre colis : en attente, en transit, arrivé au dépôt, livré.
- Notifications push automatiques à chaque changement de statut.
- Historique complet de toutes vos expéditions.

Réseau de dépôts de collecte
- Déposez et récupérez vos colis dans des dépôts de collecte en Algérie.
- Inventaire clair et à jour pour chaque dépôt.
- Gestion simple des retours et des colis non réclamés.

Offres des transporteurs
- Comparez les offres d'expédition et choisissez celle qui correspond à votre budget.
- Réservation en quelques gestes depuis l'application.
- Les transporteurs mettent à jour la progression de la livraison à chaque étape.

Messagerie intégrée
- Communiquez directement avec votre transporteur ou votre client dans l'application.
- Recevez les réponses en temps réel avec des notifications push.

Identité vérifiée
- Les transporteurs sont vérifiés (pièce d'identité et photo) pour des transactions plus sûres.
- Chaque utilisateur dispose d'un profil complet et public.

Paiement flexible
- Choisissez votre mode de paiement : espèces à la livraison, virement bancaire, CCP, ou paiement en ligne sécurisé via des prestataires agréés.

CargoLink est la solution simple et fiable pour tous vos envois de colis, où que vous soyez en Algérie.
```

---

## 3. Catégorie & pays

| Champ | Valeur |
|---|---|
| Catégorie | Voyages et transports locaux (ou Affaires → Productivité) |
| Pays de distribution | Algérie (minimum) — ajustez selon votre stratégie |
| Tranche d'âge | Adulte (18+) |
| Contenu | Familial : **Non** |

---

## 4. Sécurité des données — réponses Play Console

### Question principale
- **Votre appli collecte-t-elle ou partage-t-elle des types de données ?** → **OUI**

### Méthodes de création de compte
- ☑️ **Nom d'utilisateur et mot de passe**
- ☑️ **OAuth** (Google)

### Types de données (Étape 3)
| Type | Collecté | Partagé | Notes |
|---|---|---|---|
| Informations personnelles — Nom | ✅ | ✅ | Supabase |
| — Adresse e-mail | ✅ | ✅ | Firebase + Supabase |
| — Numéro de téléphone | ✅ | ✅ | inscription |
| — Adresse physique | ✅ | ✅ | adresses colis |
| — Autres infos personnelles | ✅ | ✅ | réseaux sociaux, photo profil |
| Infos financières — Historique des achats | ✅ | ✅ | méthode + statut paiement |
| Messages — Messages dans l'appli | ✅ | ✅ | chat |
| Photos — Photos | ✅ | ✅ | selfie, CNI/passeport, colis |
| Fichiers et documents | ✅ | ✅ | documents livraison |
| ID d'appareil — Autres ID | ✅ | ✅ | token FCM |

**NON** : localisation (aucun GPS), carte bancaire, crédit, santé, contacts, agenda, audio, vidéo, activité dans l'app, navigation web, infos de performance.

### Utilisation et traitement (Étape 4)
- **Collectées et partagées** : cocher les deux pour chaque type.
- **Traitement éphémère** : **Non**.
- **Chiffrement en transit** : **Oui** (HTTPS).
- **Suppression des données** : **Oui** — suppression de compte intégrée.
- **Finalité** : **Fonctionnement de l'appli** pour tous ; **+ Gestion des comptes** pour les infos personnelles ; **+ Communications du développeur** pour le token FCM.
- **NON** : analyse, publicité/marketing, personnalisation, prévention des fraudes.

### Fonctionnalités financières
- **Mon appli ne fournit aucune fonctionnalité financière.**

### Lien de suppression de compte
```
https://connacri.github.io/CargoLink/account_deletion.html
```

### Suppression partielle sans supprimer le compte
- **Oui** — l'utilisateur peut supprimer des données (photo, documents, messages, colis) dans l'app.

---

## 5. Politique de confidentialité (URL requise)
```
https://connacri.github.io/CargoLink/privacy_policy.html
```

---

## 6. Captures d'écran — 6 à fournir (vraies captures, pas d'illustrations)

| # | Écran | Comment l'ouvrir |
|---|---|---|
| 1 | Accueil client | Connexion → tableau de bord |
| 2 | Suivi de colis | Colis actif → écran suivi temps réel |
| 3 | Offres / Réservation | Onglet offres → réservation |
| 4 | Chat | Messagerie client/transporteur |
| 5 | Profil transporteur | Profil public vérifié |
| 6 | Dépôts de collecte | Liste des dépôts |

**Règles** :
- Format 16:9 (1080×1920 ou 1280×720 recommandés).
- Fond neutre, pas de mockup décoré, pas de texte marketing sur l'image.
- Capture sur appareil réel Android : **Power + Volume bas**, ou `adb exec-out screencap -p > capture.png`.

---

## 7. Icône, images & assets

- **Icône** : fichiers dans `playstore/assets/`.
- **Images promotionnelles / grandes images** : ne PAS utiliser de graphismes marketing — réutiliser les vraies captures si obligatoire.

---

## 8. Tags suggérés (mots-clés)

```
colis, livraison, transport, expédition, Algérie, logistique, suivi de colis, envoi de colis, dépôt de collecte, transporteur
```

---

## ⚠️ Checklist avant envoi pour examen

- [ ] Description = celle ci-dessus (fidèle aux fonctionnalités réelles)
- [ ] Captures d'écran = vraies captures, pas d'illustrations
- [ ] Lien suppression de compte renseigné
- [ ] Lien politique de confidentialité renseigné
- [ ] Chiffrement Oui / Pas d'analytics / Pas de pub
- [ ] Pas de fonctionnalité financière déclarée
- [ ] Tranche d'âge adulte, pas de contenu familial