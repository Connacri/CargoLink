# 📱 CargoLink — Fiche Google Play Store (à copier-coller)

> Tout le contenu pour remplir la Play Console. Blocs séparés par des séparateurs `---` pour copier facilement.

---

## 1. Brève description (80 caractères max)

```
CargoLink : expediez et suivez vos colis en Algerie, avec livraison securisee.
```
*(78 caractères, OK)*

---

## 2. Description complète (4000 caractères exactement)

```
CargoLink est la premiere application algerienne dediee a l'expedition et au suivi de colis entre particuliers et professionnels. Que vous soyez un particulier envoyant un colis a un proche ou un commercant gerant vos livraisons au quotidien, CargoLink simplifie chaque etape du processus d'expedition grace a une interface intuitive et des fonctionnalites completes pensees pour les utilisateurs en Algerie. Pour les expediteurs, CargoLink offre la possibilite de publier des offres d'expedition en quelques clics en renseignant le poids disponible, l'origine, la destination et les dates de depart et d'arrivee. Les transporteurs verifies proposent ensuite leurs tarifs et conditions, permettant a l'expediteur de comparer les offres et de reserver celle qui correspond le mieux a ses besoins et a son budget. Chaque transporteur est soumis a un processus de verification rigoureux incluant la validation de la piece d'identite et d'une photo, garantissant ainsi la securite et la confiance entre les parties. Le suivi en temps reel constitue l'un des piliers de CargoLink. Grace a un systeme de timeline detaille, chaque etape de la livraison est visible : reception du colis, mise en transit, arrivee au depot de destination, et livraison finale au destinataire. A chaque changement de statut, une notification push informe automatiquement le client de l'avancement de son colis. Un historique complet et detaille de toutes les expeditions est accessible a tout moment, offrant une transparence totale sur le parcours des marchandises. La messagerie integree permet aux expediteurs et transporteurs de communiquer directement dans l'application sans avoir a partager leurs coordonnees personnelles. Les echanges sont synchronises en temps reel avec des notifications push pour ne manquer aucune reponse, que ce soit pour organiser un point de retrait ou pour clarifier les details d'une livraison. CargoLink met a disposition un reseau de depots de collecte repartis sur tout le territoire algerien. Ces points relais facilitent la remise et le retrait des colis, offrant une flexibilite maximale aux utilisateurs. L'inventaire de chaque depot est maintenu a jour en temps reel pour eviter toute mauvaise surprise. Le paiement se fait selon plusieurs modalites adaptees aux habitudes locales : especes a la livraison, virement bancaire, CCP ou paiement en ligne securise via des prestataires agres. Cette diversite de choix permet a chaque utilisateur de selectionner la methode qui lui convient le mieux. Le programme de parrainage recompense la fidelite et le bouche-a-oreille : chaque parrain genere un code personnel unique qu'il partage avec ses contacts. Lorsqu'un filleul effectue sa premiere livraison, le parrain recoit une commission sur les gains realises. Un tableau de bord dedie permet de suivre en temps reel les filleuls parraines, les commissions accumulees et l'historique des paiements. Les utilisateurs peuvent signaler tout probleme ou suggerer des ameliorations via un formulaire de feedback integre, contribuant ainsi a l'amelioration continue de la plateforme. Chaque retour est analyse par l'equipe pour garantir une experience utilisateur toujours plus fluide. Un tableau de bord administrateur complet permet de gerer les utilisateurs, les annonces, les depots et les finances de la plateforme. Les fonctionnalites avancees incluent la verification des transporteurs, la gestion des litiges, le suivi des commissions et des paiements, ainsi que l'envoi de broadcasts aux utilisateurs. CargoLink s'engage sur la protection des donnees personnelles avec un chiffrement HTTPS obligatoire sur toutes les communications, aucune collecte de localisation GPS et une politique de confidentialite transparente accessible directement dans l'application. La suppression de compte est integree pour un controle total des donnees personnelles. Telechargez CargoLink aujourd'hui et decouvrez une nouvelle facon simple, securisee et en toute confiance d'expedier vos colis en Algerie.
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