# AGENTS.md — Règles du projet CargoLink

## Workflow de commit

- **Après chaque commit**, mettre à jour le fichier `playstore/VERSION_RELEASE_PLAYSTORE.md` :
  - recalculer la version de la release (schéma `1.{MINOR}.{PATCH}` : à partir de `1.0.0`,
    le patch s'incrémente à chaque commit de 0 à 99 puis rolle à 0 et la mineure s'incrémente :
    `1.0.0 → 1.0.99 → 1.1.0 → 1.1.99 → 1.2.0 …` ; versionCode = nombre total de commits
    `git rev-list --count HEAD`) ;
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

## Splash & icônes (flutter_adaptive_studio)

- Générés par l'outil CLI **flutter_adaptive_studio 0.28.11** activé globalement
  (`dart pub global activate flutter_adaptive_studio`) — PAS en dépendance pubspec
  (ses deps `archive ^4`/`xml ^7` entrent en conflit avec flutter_local_notifications).
- Config : `flutter_adaptive_studio.yaml`. Commande : `fas generate`.
- **Après chaque `fas generate`, re-appliquer les 3 patches documentés en tête du yaml**
  (supprimer le logo centré en doublon : launch_background.xml ×2, splash_icon_legacy*,
  `logo: null` dans lib/fas_splash.g.dart) — splash2.png est une image plein écran
  qui contient déjà le logo.
- Le fichier généré `lib/fas_splash.g.dart` importe `dart:ffi` (indisponible sur web) :
  ne jamais l'importer directement — passer par `lib/core/widgets/app_splash_gate.dart`
  (import conditionnel io/web).

## Diagnostics Supabase

- L'outil MCP `supabase_query_logs` renvoie « Backend error! » systématique (service de
  logs analytics indisponible pour ce projet). Ne pas insister.
- Contournement : requêtes SQL via `supabase_execute_sql` —
  - Requêtes lentes/coûteuses : table `pg_stat_statements` (extension installée),
    trier par `total_exec_time` ;
  - Activité temps réel : `pg_stat_activity` ;
  - Verrous : `pg_locks` joint `pg_stat_activity`.
