# UI Refonte — Contract de refonte des écrans CargoLink

Refonte UI/UX premium des écrans. Règles strictes ci-dessous.

## Design tokens (déjà en place)
`lib/core/theme/app_theme.dart` — classe `AppTheme` :
- Couleurs : `primaryColor` (#6366F1), `primaryDark`, `primaryLight`, `primaryLighter`, `accentColor` (#10B981), `warningColor`, `errorColor`, `infoColor`, `backgroundColor`, `surfaceColor`, `surfaceMuted`, `dividerColor`, `textPrimaryColor`, `textSecondaryColor`, `textMutedColor`.
- Dégradés : `primaryGradient`, `successGradient`, `warningGradient`, `errorGradient`, `infoGradient`, `darkGradient`.
- Ombres : `shadowSm`, `shadowMd`, `shadowLg` (getters).
- Radius : `radiusXs=8`, `radiusSm=12`, `radiusMd=16`, `radiusLg=24`, `radiusXl=32`.
- Spacing : `spaceXs=4`, `spaceSm=8`, `spaceMd=16`, `spaceLg=24`, `spaceXl=32`, `spaceXxl=48`.
- Text styles : `h1`, `h2`, `h3`, `body`, `bodySecondary`, `caption`, `label`.
- Helpers : `cardDecoration()`, `softDecoration(color)`.

## UI kit partagé (import: `package:cargolink/core/widgets/ui_kit.dart`)
Exporte :

- **`GradientSliverHeader`** : header dégradé dans un CustomScrollView.
  ```dart
  GradientSliverHeader(
    title: 'Titre', subtitle: 'Sous-titre', icon: Icons.x,
    trailing: widget, gradient: AppTheme.primaryGradient, expandedHeight: 180,
  )
  ```

- **`GlassCard`** : carte premium cliquable ou non.
  ```dart
  GlassCard(onTap: fn, child: ...) // padding: EdgeInsets, radius: double
  ```
  Pas de paramètre `margin` — wrapper dans `Padding`.

- **`GradientBadge`** : pill dégradé (status). `GradientBadge(label, gradient, icon)`.

- **`GradientAvatar`** : avatar cercle avec dégradé. `GradientAvatar(initial, imageUrl, radius, onTap)`.

- **`AnimatedIconDot`** : icône sur pastille colorée. `AnimatedIconDot(icon, color)`.

- **`StaggeredEntrance`** : apparition animée en cascade.
  ```dart
  StaggeredEntrance(delay: Duration(milliseconds: index*40), child: ...)
  ```

- **`ShimmerCard`** / **`ShimmerBox`** : skeletons de chargement.

- **`PaginatedList<T>`** : état paginé (objet), avec `items`, `hasMore`, `loading`, `initialLoading`, `error`, `loadInitial()`, `loadMore()`, `refresh()`.

- **`PaginatedListNotifier<T>`** : `StateNotifier<PaginatedList<T>>` avec `loadInitial()`, `loadMore()`, `refresh()`.
  Factory : `createPaginatedNotifier<T>((limit, offset) async => loader, pageSize: 15)`.

- **`PagedSliverList<T>`** : SliverList lazy + infinite scroll.
  ```dart
  PagedSliverList<T>(
    paginatedList: list,           // PaginatedList<T>
    itemBuilder: (context, item, index) => widget,
    padding: EdgeInsets,
    emptyState: widget,
    skeletonCount: 6,
  )
  ```
  Gère shimmer initial, erreur+retry, empty state, et déclenche `loadMore()` en bas.

- **`PagedSliverGrid<T>`** : idem mais grid. Paramètre `gridDelegate`.
  ```dart
  PagedSliverGrid<T>(
    paginatedList: list,
    itemBuilder: (context, item, index) => widget,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, ...),
  )
  ```

## Règle n°1 — LAZY / PAGINATION (obligatoire)
TOUTE liste/grid qui affiche des données potentiellement longues (shipments, bookings, payments, users, disputes, notifications, tracking history) DOIT être refondue en **`CustomScrollView` + slivers** avec **pagination infinie** via `PagedSliverList`/`PagedSliverGrid` + `PaginatedListNotifier`. 

- **Interdit** : `ListView.builder` + `shrinkWrap: true` + `NeverScrollableScrollPhysics` imbriqué (nested scroll). Interdit `SingleChildScrollView` contenant des listes.
- Les `SingleChildScrollView` horizontaux (chips, etc.) restent OK.
- Pattern provider paginé (à mettre en haut du fichier de l'écran) :
  ```dart
  final myListProvider = StateNotifierProvider.family<
      PaginatedListNotifier<T>, PaginatedList<T>, ({int p1})>((ref, p) {
    return createPaginatedNotifier(
      (limit, offset) => ref.read(myServiceProvider).getX(limit: limit, offset: offset),
      pageSize: 15,
    );
  });
  ```
  puis dans le StatefulWidget : relire `loadInitial()` quand les params changent (`didChangeDependencies`), et le widget consomme `ref.watch(myListProvider(param))`.

- Les petits compteurs/stats courts (stats, métriques) peuvent rester en `FutureProvider` non paginé.

## Règle n°2 — Structure des écrans
- Utiliser `CustomScrollView` comme racine (pas d'`AppBar` standard ; utiliser `GradientSliverHeader` pour les écrans principaux, `SliverAppBar` simple pour les écrans de détail si plus pertinent).
- Entrée en cascade : `StaggeredEntrance` sur les items de listes/grids.
- Loading : `ShimmerCard` (listes) au lieu de `CircularProgressIndicator` plein écran.
- Chaque item de liste doit être beau : `GlassCard`, icônes rondes `AnimatedIconDot`, prix/badges `GradientBadge`.

## Règle n°3 — Consistance
- Couleurs : seulement via tokens `AppTheme.*`. Pas de couleurs en dur (sauf blanc/noir/ambre).
- Ne PAS supprimer la logique métier existante (appels service, navigation). Seule la présentation change + passage en pagination.
- Ne pas toucher `app_theme.dart`, ni `ui_kit.dart`, ni les providers/services.
- Garder les `routes`/arguments inchangés.

## Vérification
Après refonte d'un fichier : `flutter analyze lib/screens/...` — corriger les `error` (les `info` non bloquantes sont tolérées). Ne jamais introduire de nouvelles `error`/`warning`.
