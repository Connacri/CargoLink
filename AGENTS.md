# AGENTS.md — Règles du projet CargoLink

## Workflow de commit

- **Après chaque commit**, mettre à jour le fichier `playstore/VERSION_RELEASE_PLAYSTORE.md` :
  - recalculer la version de la release (versionName = dernier tag `vX.Y.Z` + 1 par commit
    depuis le tag ; versionCode = nombre total de commits `git rev-list --count HEAD`) ;
  - mettre à jour le tableau « Dernière version » (versionName, versionCode, commit de
    référence, statut CI, lien de téléchargement du `app-release.aab`) ;
  - ajouter les nouveautés de la version dans la section « Contenu de cette version » ;
  - committer ensuite cette mise à jour (docs) et pousser.
- Messages de commit : en français, style `feat:`, `fix:`, `docs:`, `chore:`.
- Pousser après chaque commit (la CI `release.yml` produit le AAB signé pour la Play Console).

## Play Store

- Package : `com.cargolink.dz.cargolink`. AAB signé publié automatiquement en GitHub Release.
- Fiche Play Store prête à copier : `playstore/PLAY_STORE_FICHE.md`.
- Politique de confidentialité : https://connacri.github.io/CargoLink/privacy_policy.html
- Suppression de compte : https://connacri.github.io/CargoLink/account_deletion.html

## Qualité (avant de commit/push)

- Lancer `flutter analyze` (0 issue) puis `flutter test` (tous verts).
- Les builds web (`flutter build web --release`) et Android (`flutter build apk --debug`)
  doivent compiler.
