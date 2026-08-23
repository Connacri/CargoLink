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
- **NE JAMAIS builder localement** (ni `flutter build web --release`, ni
  `flutter build apk --debug`, ni aucun autre build) : la compilation est
  validée par la CI (`release.yml`) après le push. Ne pas perdre de temps
  local dessus.
- **Toujours committer et pousser** dès qu'une tâche demandée est terminée
  (code puis docs, cf. workflow ci-dessus).

## Splash & icônes (flutter_native_splash + flutter_launcher_icons)

- Configs dans `pubspec.yaml` (sections `flutter_launcher_icons` et `flutter_native_splash`),
  source unique du logo : `assets/icons/icon2.png`, splash plein écran : `assets/icons/splash2.png`.
- Icônes : `dart run flutter_launcher_icons`.
- Splash : `dart run flutter_native_splash:create`.
- NE PAS utiliser flutter_adaptive_studio : tenté en v1.0.11 puis retiré (icône/splash
  déformés — foreground non adapté au masque, logo dupliqué sur Android 12+).

## Diagnostics Supabase

- L'outil MCP `supabase_query_logs` renvoie « Backend error! » systématique (service de
  logs analytics indisponible pour ce projet). Ne pas insister.
- Contournement : requêtes SQL via `supabase_execute_sql` —
  - Requêtes lentes/coûteuses : table `pg_stat_statements` (extension installée),
    trier par `total_exec_time` ;
  - Activité temps réel : `pg_stat_activity` ;
  - Verrous : `pg_locks` joint `pg_stat_activity`.
