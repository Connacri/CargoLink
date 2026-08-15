# 🎬 CargoLink — Tutoriel Animations (pour une autre IA / agent)

> Guide **exhaustif et autocontenu** pour qu'une autre IA (ou un développeur) puisse créer, modifier ou étendre les animations de CargoLink **sans re-explorer le code**. Il décrit l'inventaire actuel, le design system, les patterns exacts à respecter, puis des tutos pas-à-pas (avec code prêt à l'emploi) pour chaque type d'animation.

---

## 1. Inventaire actuel des animations (audit du code)

### 1.1 Fichiers concernés
| Fichier | Contenu |
|---|---|
| `lib/core/widgets/animations.dart` | `StaggeredEntrance` (réelle) + `AnimatedIconDot` (**no-op**, statique) |
| `lib/core/widgets/shimmer.dart` | `ShimmerBox` (réelle) + `ShimmerCard` (skeleton complet) |
| `lib/core/widgets/fade_in_scroll.dart` | `FadeInOnScroll` (**no-op**, statique) |
| `lib/core/widgets/glass_card.dart` | `GlassCard`, `GradientBadge`, `GradientAvatar` (UI, animations implicites via Material) |
| `lib/core/theme/app_theme.dart` | Design tokens (couleurs, gradients, radius, spacing, text) |

### 1.2 Ce qui est réellement animé aujourd'hui
1. **`StaggeredEntrance`** (`animations.dart:7-63`) : apparition en cascade — fondu + glissement, configurable.
   - Paramètres : `delay` (par ex. `index * 50ms`), `offset` (défaut `Offset(0, 24)`), `duration` (défaut 420 ms), `curve` (défaut `Curves.easeOutCubic`).
   - Mécanisme : `AnimationController` + `Tween<Offset>` + `Tween<double>` (opacité) + `Future.delayed` pour le stagger.
2. **`ShimmerBox`** (`shimmer.dart:9-81`) : skeleton animé — gradient mobile (alignement animé de `(-1.5,0)` à `(1.5,0)`, boucle `repeat()`, 1400 ms, `Curves.easeInOut`).
3. **`ShimmerCard`** (`shimmer.dart:84-124`) : carte skeleton (image + lignes) construite à partir de `ShimmerBox`.
4. Animations **implicites** Material 3 : boutons, ripple (`InkSparkle`), transitions de routes, `InkWell`.

### 1.3 Ce qui est déclaré mais PAS animé (no-ops / à implémenter)
- **`AnimatedIconDot`** (`animations.dart:66-89`) : le nom promet une « pulsation », mais le widget rend une pastille **statique** (`Container` + `Icon`). C'est un **placeholder**.
- **`FadeInOnScroll`** (`fade_in_scroll.dart:5-25`) : doit faire apparaître l'enfant au défilement ; actuellement renvoie `Opacity(1)` + `Transform.translate(0,0)` → **aucun effet**.
- **Lottie** : `pubspec.yaml` déclare `lottie`, mais **aucun** `Lottie.asset` n'est utilisé dans le code.
- **Timeline de suivi** (`tracking_timeline.dart`) : rend les étapes sans animation explicite.

---

## 2. Design system (tokens à utiliser systématiquement)

Importer : `import '../core/theme/app_theme.dart';` — ne PAS hardcoder les couleurs.

### Couleurs
`primaryColor` (#6366F1), `primaryDark` (#4F46E5), `primaryDeep` (#4338CA), `primaryLight` (#E0E7FF), `primaryLighter` (#EEF2FF), `accentColor` (#10B981), `accentDark` (#059669), `warningColor` (#F59E0B), `errorColor` (#EF4444), `errorDark` (#DC2626), `infoColor` (#0EA5E9), `backgroundColor` (#F8FAFC), `surfaceColor` (#FFF), `surfaceMuted` (#F1F5F9), `dividerColor` (#E2E8F0), `textPrimaryColor` (#1E293B), `textSecondaryColor` (#64748B), `textMutedColor` (#94A3B8).

### Dégradés
`primaryGradient` (indigo → violet), `successGradient`, `warningGradient`, `errorGradient`, `infoGradient`, `darkGradient`.

### Ombres
`AppTheme.shadowSm`, `shadowMd`, `shadowLg` (getters `List<BoxShadow>`).

### Radius
`radiusXs=8`, `radiusSm=12`, `radiusMd=16`, `radiusLg=24`, `radiusXl=32`.

### Spacing
`spaceXs=4`, `spaceSm=8`, `spaceMd=16`, `spaceLg=24`, `spaceXl=32`, `spaceXxl=48`.

### Text styles
`h1` (28/800), `h2` (22/700), `h3` (18/600), `body` (14), `bodySecondary` (14 gris), `caption` (12 gris), `label` (12/600).

### Helpers
`AppTheme.cardDecoration()` → `BoxDecoration` (surface + radiusMd + shadowSm). `AppTheme.softDecoration(color)` → fond teinté radiusSm.

---

## 3. Pattern technique obligatoire (règles à respecter)

1. **Toujours** `SingleTickerProviderStateMixin` (ou `TickerProviderStateMixin`) et `AnimationController` dans `initState`, `dispose()` le contrôleur.
2. **Ne jamais** utiliser `AnimatedBuilder`/`ListenableBuilder` en dehors du `builder` pour lire la valeur de l'animation (sinon le widget ne se rebuild pas).
3. Durées conseillées : micro (150-250 ms, feedback boutons), standard (300-450 ms, entrées), décoratif (800-1400 ms, boucles shimmer/pulsations).
4. Courbes : entrée → `Curves.easeOutCubic`/`easeOut` ; boucle → `Curves.easeInOut` ; rebond → `Curves.elasticOut` (élastique, réserver aux accents).
5. Pour une **cascade** : `delay: Duration(milliseconds: index * 50)` (ou 40) et passer par `Future.delayed` (pattern déjà utilisé dans `StaggeredEntrance`).
6. **Opacité + déplacement ensemble** (fade+slide) : `FadeTransition` imbriqué dans `SlideTransition` (voir `StaggeredEntrance`).
7. UI française : chaînes en français.
8. Après tout changement : `flutter analyze` sans **error/warning** (les `info` sont tolérées), `flutter test` vert.

---

## 4. Tutoriel 1 — Animer l'icône de statut (rendre `AnimatedIconDot` réel)

Objectif : transformer le no-op en pastille qui **pulse doucement** (scale + halo).

### Étapes
1. Ouvrir `lib/core/widgets/animations.dart`.
2. Convertir `AnimatedIconDot` en `StatefulWidget` avec `SingleTickerProviderStateMixin`.
3. Créer un `AnimationController(duration: 900ms)..repeat(reverse: true)`.
4. Animer `scale` de `1.0` à `1.08` et l'opacité du halo de `0.12` à `0.2`.
5. Wrap le `Container` dans `ScaleTransition`.

### Code (remplacer tout le widget)
```dart
/// A single-line animated icon that pulses softly.
class AnimatedIconDot extends StatefulWidget {
  const AnimatedIconDot({
    super.key,
    required this.icon,
    required this.color,
    this.size = 18,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  State<AnimatedIconDot> createState() => _AnimatedIconDotState();
}

class _AnimatedIconDotState extends State<AnimatedIconDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _halo;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(curved);
    _halo = Tween<double>(begin: 0.12, end: 0.22).animate(curved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: widget.size + 14,
        height: widget.size + 14,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _halo.value),
          borderRadius: BorderRadius.circular(widget.size),
        ),
        child: ScaleTransition(
          scale: _scale,
          child: Icon(widget.icon, color: widget.color, size: widget.size),
        ),
      ),
    );
  }
}
```
> Note : `.withValues(alpha: ...)` est l'API actuelle du codebase (à la place de `.withOpacity`). Ne pas réintroduire `withOpacity`.

---

## 5. Tutoriel 2 — Fade-in au scroll (rendre `FadeInOnScroll` réel)

Objectif : l'enfant apparaît (fondu + léger slide) quand il entre dans le viewport.

### Approche recommandée (sans dépendance)
Utiliser `Scrollable.ensureVisible`/`NotificationListener` est lourd ; la méthode simple et fiable est d'utiliser un `TweenAnimationBuilder` déclenché à l'init (fondu d'entrée), ou un vrai scroll-driven via `VisibilityDetector` (dépendance non présente). On fournit ici la version **entrée différée** + une variante scroll-driven basée sur `ScrollNotification`.

### Version simple (fondu d'entrée avec délai)
```dart
class FadeInOnScroll extends StatelessWidget {
  const FadeInOnScroll({
    super.key,
    required this.child,
    this.offset = 24,
    this.duration = const Duration(milliseconds: 500),
  });

  final Widget child;
  final double offset;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, offset * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
```

### Version scroll-driven (véritable fade au défilement)
```dart
class FadeInOnScroll extends StatefulWidget {
  const FadeInOnScroll({
    super.key,
    required this.child,
    this.offset = 24,
    this.threshold = 0.2,
  });

  final Widget child;
  final double offset;
  final double threshold; // fraction du viewport nécessaire pour être « visible »

  @override
  State<FadeInOnScroll> createState() => _FadeInOnScrollState();
}

class _FadeInOnScrollState extends State<FadeInOnScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isVisible(BuildContext context) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return false;
    final viewport = context.findRenderObject() as RenderBox?;
    if (viewport == null) return true;
    final top = box.localToGlobal(Offset.zero).dy;
    final height = box.size.height;
    final viewportBottom = viewport.size.height * (1 - widget.threshold);
    return top < viewportBottom && top + height > 0;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        if (!_controller.isCompleted && _isVisible(context)) {
          _controller.forward();
        }
        return false;
      },
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, widget.offset / 100),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
          child: Container(key: _key, child: widget.child),
        ),
      ),
    );
  }
}
```

---

## 6. Tutoriel 3 — Timeline de suivi animée (composant tracking)

Objectif : chaque étape de la timeline s'anime (fill progressif + apparition en cascade) selon le statut courant.

### Contexte
`lib/components/tracking_timeline.dart` rend les étapes avec statut/description et boutons. Les statuts suivent l'ordre :
```
order_processed → collected → departed_origin → in_transit
→ arrived_destination → customs_cleared → out_for_delivery → delivered
```

### Approche
1. Calculer `currentIndex` = position de l'étape courante dans la liste.
2. Pour chaque étape `i` :
   - `StaggeredEntrance(delay: Duration(milliseconds: i * 60))` pour l'apparition ;
   - un point/bullet `completed` (i ≤ currentIndex) animé via `TweenAnimationBuilder` : fill `0→1`, couleur `surfaceMuted → primaryColor`, scale `1.0 → 1.15` puis retour.
   - une ligne de connexion entre bullets dont la longueur est animée (`FractionallySizedBox` avec `AlignmentGeometryTween` ou `ScaleX`).
3. Boutons d'action (ex. « Confirmer la réception ») avec `ScaleTransition` (tap bounce) — ou rester sur le ripple Material natif.

### Squelette (à adapter au widget existant)
```dart
// Dans le builder d'une étape :
AnimatedBuilder(
  animation: _fillController,
  builder: (context, _) {
    final filled = i <= currentIndex ? 1.0 : 0.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(AppTheme.surfaceMuted, AppTheme.primaryColor, filled),
      ),
    );
  },
)
```
> Toutes les transitions doivent utiliser les tokens `AppTheme.*`.

---

## 7. Tutoriel 4 — Shimmer / skeleton avancé

### Réutiliser l'existant
- `ShimmerBox(width, height, radius, shape)` : rectangle/cercle animé. Déjà lazy-safe (fonctionne dans `SliverList`/`SliverGrid`).
- `ShimmerCard(imageHeight, lines)` : carte complète pour les listes.

### Étendre
1. **Shimmer circulaire** : `ShimmerBox(shape: BoxShape.circle, width: 48, height: 48)`.
2. **Personnaliser la vitesse** : le `duration` est codé en dur (1400 ms) ; pour le rendre paramétrable, ajouter un paramètre `duration` au constructeur de `ShimmerBox` et le passer à l'`AnimationController`.
3. **Texte shimmer** : combiner `ShimmerBox(width: w, height: 12)` avec `AppTheme.spaceSm`.

---

## 8. Tutoriel 5 — Entrée en cascade sur une liste (bonne pratique)

Pattern déjà en place (à appliquer partout où manquant) :

```dart
PagedSliverList<Shipper>(
  paginatedList: list,
  itemBuilder: (context, item, index) => StaggeredEntrance(
    delay: Duration(milliseconds: index * 50),
    child: ShipperCard(shipper: item),
  ),
  ...
)
```

Règles :
- `index` vient de l'`itemBuilder` (pagination). Pour éviter que tous les items d'une nouvelle page ne réapparaissent, on peut conditionner le stagger aux `index < 20` (première page) ou utiliser un clé stable (`ValueKey(item.id)`) et un `TweenAnimationBuilder` avec `delay` croissant.
- Toujours `StaggeredEntrance` à l'intérieur du `SliverList` item (pas autour de la liste entière).

---

## 9. Tutoriel 6 — Lottie (dépendance déjà déclarée)

`pubspec.yaml` contient `lottie`. Usage type (une fois l'asset présent dans `assets/`) :

```dart
Lottie.asset(
  'assets/lottie/package_delivery.json',
  width: 200,
  height: 200,
  fit: BoxFit.contain,
)
```

Étapes pour l'ajouter proprement :
1. Créer le dossier `assets/lottie/` et y déposer un `.json` Lottie.
2. Déclarer le dossier dans `pubspec.yaml` → `flutter: assets: - assets/lottie/`.
3. Utiliser `Lottie.asset(...)` dans l'écran (ex. écran de succès après paiement).
4. **Garde-fou** : les Lottie sont lourds ; limiter leur usage à 1-2 écrans (feedback de succès), préférer les animations code pour le reste.

---

## 10. Tutoriel 7 — Transition de page / Hero (si souhaité)

Actuellement les routes sont gérées par `app.dart` (route names). Pour ajouter une transition fluide entre liste et détail :

```dart
// Dans app.dart, pour une route de détail :
Navigator.of(context).push(
  PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => const DetailScreen(...),
    transitionsBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  ),
);
```

> Ne PAS toucher aux routes/arguments existants (`app.dart`). Ajouter des transitions optionnelles uniquement.

---

## 11. Checklist finale (à donner à l'IA avant chaque livraison)

- [ ] Pas de `withOpacity` (utiliser `withValues(alpha:)`).
- [ ] Pas de couleur en dur (sauf blanc/noir/ambre) — tokens `AppTheme.*`.
- [ ] `AnimationController` disposé dans `dispose()`.
- [ ] `flutter analyze` → 0 error, 0 warning.
- [ ] `flutter test` → vert.
- [ ] Chaînes en français.
- [ ] Pagination : animations dans l'`itemBuilder` du sliver, pas autour de la liste.
- [ ] Les widgets no-ops (`AnimatedIconDot`, `FadeInOnScroll`) → réellement animés avant d'être « documentés » comme animés.