// =============================================================================
// CabaLink — page de présentation & simulateur de commission (bilingue AR/FR)
// -----------------------------------------------------------------------------
// Fichier autonome, aucune dépendance externe (uniquement flutter/material.dart,
// dart:math et les fichiers de contenu cabalink_guide_*).
//
// Contenu:
//   - CabaLinkPromoBanner : carte/bannière à placer sur l'écran d'accueil,
//                           ouvre CabaLinkPage via une transition Hero.
//   - CabaLinkPage        : la page elle-même (CustomScrollView à slivers),
//                           les 43 points du guide en français et en arabe,
//                           direction RTL en arabe, chiffres et simulateurs
//                           restant en orientation LTR.
//
// SDK visé: Flutter 3.19+ / Dart 3.x (Material 3 natif : SegmentedButton,
// FilledButton, Card.filled, SliverAppBar.stretch...).
// =============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'cabalink_guide_catalog.dart';
import 'cabalink_guide_content.dart';

// -----------------------------------------------------------------------------
// Identifiants partagés (Hero, routes)
// -----------------------------------------------------------------------------

const String cabaLinkHeroTag = 'cabalink-luggage-tag';

// -----------------------------------------------------------------------------
// Palette & thème
// -----------------------------------------------------------------------------

class _CabaLinkColors {
  _CabaLinkColors._();

  static const Color deepNight = Color(0xFF0A1428);
  static const Color inkNavy = Color(0xFF12213D);
  static const Color altitudeTeal = Color(0xFF1D6F74);
  static const Color tagBrass = Color(0xFFC79A3B);
  static const Color tagBrassLight = Color(0xFFE0BE6E);
  static const Color runwayCoral = Color(0xFFD9564A);
  static const Color manifestPaper = Color(0xFFEEF0F1);
  static const Color manifestWhite = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF141B2C);
  static const Color inkMuted = Color(0xFF6B7280);
}

ThemeData _cabaLinkTheme(BuildContext context) {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: _CabaLinkColors.altitudeTeal,
    brightness: Brightness.light,
  ).copyWith(
    primary: _CabaLinkColors.inkNavy,
    onPrimary: _CabaLinkColors.manifestWhite,
    secondary: _CabaLinkColors.tagBrass,
    onSecondary: _CabaLinkColors.deepNight,
    tertiary: _CabaLinkColors.altitudeTeal,
    surface: _CabaLinkColors.manifestWhite,
    onSurface: _CabaLinkColors.ink,
    error: _CabaLinkColors.runwayCoral,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: _CabaLinkColors.manifestPaper,
    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
    splashFactory: InkSparkle.splashFactory,
  );
}

TextStyle _flapNumberStyle({required double size, Color? color}) {
  return TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    height: 1.0,
    color: color ?? _CabaLinkColors.ink,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

// -----------------------------------------------------------------------------
// Helpers partagés
// -----------------------------------------------------------------------------

int _clampedFlex(double value) => value.round().clamp(1, 1 << 30).toInt();

String _formatNumber(double value) {
  final int rounded = value.round();
  final String digits = rounded.abs().toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('\u202F');
    buffer.write(digits[i]);
  }
  return (rounded < 0 ? '-' : '') + buffer.toString();
}

Widget _sectionPadding({EdgeInsetsGeometry? padding, required Widget child}) {
  return Padding(
    padding: padding ?? const EdgeInsets.fromLTRB(20, 32, 20, 0),
    child: child,
  );
}

Widget _aysSectionHeader({
  required bool isArabic,
  required CabalinkL10n title,
  CabalinkL10n? subtitle,
  CabalinkL10n? eyebrow,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (eyebrow != null) ...[
        Text(
          eyebrow.pick(isArabic: isArabic).toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: _CabaLinkColors.tagBrass,
          ),
        ),
        const SizedBox(height: 8),
      ],
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            title.pick(isArabic: isArabic),
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: _CabaLinkColors.ink,
              height: 1.15,
            ),
          ),
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(
          subtitle.pick(isArabic: isArabic),
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: _CabaLinkColors.inkMuted,
          ),
        ),
      ],
    ],
  );
}

// -----------------------------------------------------------------------------
// CabaLinkPromoBanner — à déposer sur l'écran d'accueil (client_home_screen)
// =============================================================================

class CabaLinkPromoBanner extends StatelessWidget {
  const CabaLinkPromoBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: _CabaLinkColors.inkNavy,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: onTap ??
              () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 480),
                    reverseTransitionDuration: const Duration(milliseconds: 380),
                    pageBuilder: (_, animation, __) => const CabaLinkPage(),
                    transitionsBuilder: (_, animation, __, child) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      );
                      return FadeTransition(
                        opacity: curved,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.04),
                            end: Offset.zero,
                          ).animate(curved),
                          child: child,
                        ),
                      );
                    },
                  ),
                );
              },
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _BannerRoutePainter()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                child: Row(
                  children: [
                    const Hero(
                      tag: cabaLinkHeroTag,
                      child: _LuggageTagBadge(size: 56),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CabaLink',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Transformez le poids inutilisé de vos voyages en revenu',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.72),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: _CabaLinkColors.tagBrass,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: _CabaLinkColors.deepNight,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint dot = Paint()..color = Colors.white.withOpacity(0.08);
    final path = Path()
      ..moveTo(size.width * 0.55, size.height * 1.1)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.15,
        size.width * 1.05,
        size.height * 0.35,
      );
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, 2.2, dot);
        }
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LuggageTagBadge extends StatelessWidget {
  const _LuggageTagBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _CabaLinkColors.tagBrass,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: _CabaLinkColors.tagBrass.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.luggage,
        color: _CabaLinkColors.deepNight,
        size: size * 0.52,
      ),
    );
  }
}

// =============================================================================
// CabaLinkPage — la page complète (43 points, FR/AR)
// =============================================================================

class CabaLinkPage extends StatefulWidget {
  const CabaLinkPage({super.key, this.onSearchPressed, this.onPublishPressed});

  /// Appelé quand l'utilisateur touche "Rechercher un voyage".
  final VoidCallback? onSearchPressed;

  /// Appelé quand l'utilisateur touche "Publier mon voyage".
  final VoidCallback? onPublishPressed;

  @override
  State<CabaLinkPage> createState() => _CabaLinkPageState();
}

class _CabaLinkPageState extends State<CabaLinkPage> {
  bool _isArabic = false;

  TextDirection get _direction =>
      _isArabic ? TextDirection.rtl : TextDirection.ltr;

  void _toggleLanguage() => setState(() => _isArabic = !_isArabic);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CabaLinkColors.manifestPaper,
      body: Theme(
        data: _cabaLinkTheme(context),
        child: Directionality(
          textDirection: _direction,
child: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(child: _buildIntro()),
              SliverToBoxAdapter(child: _buildStats()),
              const SliverToBoxAdapter(child: _RolesCarousel()),
              SliverToBoxAdapter(child: _buildWeightCard()),
              SliverToBoxAdapter(child: _buildSimulator()),
              SliverToBoxAdapter(child: _buildAmbassador()),
              _buildPrinciples(),
              SliverToBoxAdapter(child: _buildChaptersHeader()),
              _buildChapters(),
              SliverToBoxAdapter(child: _buildBottomBar(context)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SliverAppBar + héros
  // ---------------------------------------------------------------------------

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 344,
      pinned: true,
      stretch: true,
      backgroundColor: _CabaLinkColors.inkNavy,
      foregroundColor: Colors.white,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _LanguageToggle(
            isArabic: _isArabic,
            onChanged: _toggleLanguage,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: _HeroHeader(isArabic: _isArabic),
      ),
    );
  }

  Widget _buildIntro() {
    return _sectionPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CabalinkGuideUi.title.pick(isArabic: _isArabic),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _CabaLinkColors.ink,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CabalinkGuideUi.subtitle.pick(isArabic: _isArabic),
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: _CabaLinkColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return _sectionPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          _StatTile(
            value: kCabaLinkCommissionPerKg,
            decimals: 0,
            unit: '€/kg',
            label: CabalinkGuideUi.statsCommission.pick(isArabic: _isArabic),
          ),
          const SizedBox(width: 10),
          _StatTile(
            value: kCabaLinkCommissionDzdPerKg(),
            decimals: 0,
            unit: 'DZD/kg',
            label: CabalinkGuideUi.statsDzd.pick(isArabic: _isArabic),
          ),
          const SizedBox(width: 10),
          _StatTile(
            value: kCabaLinkRateDzd,
            decimals: 0,
            unit: 'DZD',
            label: CabalinkGuideUi.statsRate.pick(isArabic: _isArabic),
          ),
          const SizedBox(width: 10),
          _StatTile(
            value: cabalinkGuideSections.length.toDouble(),
            decimals: 0,
            unit: '',
            label: CabalinkGuideUi.statsGuidePoints.pick(isArabic: _isArabic),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightCard() {
    return _sectionPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _aysSectionHeader(
            isArabic: _isArabic,
            title: CabalinkGuideUi.highlightWeight,
            subtitle: CabalinkGuideUi.highlightWeightSub,
          ),
          const SizedBox(height: 16),
          Directionality(
            textDirection: TextDirection.ltr,
            child: _WeightGaugeCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulator() {
    return _sectionPadding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _aysSectionHeader(
            isArabic: _isArabic,
            title: CabalinkGuideUi.highlightSim,
            subtitle: CabalinkGuideUi.highlightSimSub,
          ),
          const SizedBox(height: 16),
          const Directionality(
            textDirection: TextDirection.ltr,
            child: _CommissionSimulator(),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbassador() {
    return _sectionPadding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _aysSectionHeader(
            isArabic: _isArabic,
            title: CabalinkGuideUi.highlightAmbassador,
            subtitle: CabalinkGuideUi.highlightAmbassadorSub,
          ),
          const SizedBox(height: 16),
          const _AmbassadorPass(),
        ],
      ),
    );
  }

  Widget _buildPrinciples() {
    final bool isArabic = _isArabic;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: _aysSectionHeader(
              isArabic: isArabic,
                title: CabalinkGuideUi.highlightPrinciples,
              subtitle: CabalinkGuideUi.highlightPrinciplesSub,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _PrincipleTile(
                  principle: cabalinkPrinciples[index],
                  isArabic: isArabic,
                ),
                childCount: cabalinkPrinciples.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChaptersHeader() {
    return _sectionPadding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: _aysSectionHeader(
        isArabic: _isArabic,
        eyebrow: CabalinkGuideUi.chaptersEyebrow,
        title: CabalinkGuideUi.chaptersTitle,
        subtitle: CabalinkGuideUi.chaptersSub,
      ),
    );
  }

  Widget _buildChapters() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final section = cabalinkGuideSections[index];
          return Padding(
            padding: EdgeInsets.fromLTRB(
              _isArabic ? 20 : 20,
              index == 0 ? 20 : 8,
              _isArabic ? 20 : 20,
              index == cabalinkGuideSections.length - 1 ? 8 : 0,
            ),
            child: _ChapterTile(section: section, isArabic: _isArabic),
          );
        },
        childCount: cabalinkGuideSections.length,
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return _sectionPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                CabalinkGuideUi.conclusion.pick(isArabic: _isArabic),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _CabaLinkColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _CabaLinkColors.inkNavy,
                  ),
                  onPressed: widget.onSearchPressed ?? () {},
                  icon: const Icon(Icons.search),
                  label: Text(
                    CabalinkGuideUi.bottomCtaSearch.pick(isArabic: _isArabic),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _CabaLinkColors.tagBrass,
                    foregroundColor: _CabaLinkColors.deepNight,
                  ),
                  onPressed: widget.onPublishPressed ?? () {},
                  icon: const Icon(Icons.add),
                  label: Text(
                    CabalinkGuideUi.bottomCtaPublish.pick(isArabic: _isArabic),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Héros animé
// =============================================================================

class _HeroHeader extends StatefulWidget {
  const _HeroHeader({required this.isArabic});

  final bool isArabic;

  @override
  State<_HeroHeader> createState() => _HeroHeaderState();
}

class _HeroHeaderState extends State<_HeroHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool ar = widget.isArabic;
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _CabaLinkColors.deepNight,
                _CabaLinkColors.inkNavy,
                _CabaLinkColors.altitudeTeal,
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => CustomPaint(
              painter: _HeroRoutePainter(progress: _controller.value),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                const Center(
                  child: Hero(
                    tag: cabaLinkHeroTag,
                    child: _LuggageTagBadge(size: 92),
                  ),
                ),
                const SizedBox(height: 16),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Center(
                      child: Text(
                        CabalinkGuideUi.appTitle.pick(isArabic: ar),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    CabalinkGuideUi.tagline.pick(isArabic: ar),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroRoutePainter extends CustomPainter {
  const _HeroRoutePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * -0.1, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.05,
        size.width * 1.1,
        size.height * 0.6,
      );

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;

    final fade = (math.sin(progress * math.pi * 2) * 0.5 + 0.5).clamp(0.2, 1.0);

    final Paint trail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2
      ..color = _CabaLinkColors.tagBrass.withOpacity(0.5 * fade);
    canvas.drawPath(path, trail);

    final tangent = metric.getTangentForOffset(metric.length * progress);
    if (tangent != null) {
      final Paint dot = Paint()..color = _CabaLinkColors.tagBrassLight;
      canvas.drawCircle(tangent.position, 6, dot);
      canvas.drawCircle(
        tangent.position.translate(-14, 4),
        3,
        dot..color = Colors.white.withOpacity(0.5),
      );
    }

    for (final m in metrics) {
      double d = 0;
      while (d < m.length) {
        final t = m.getTangentForOffset(d);
        if (t != null) {
          canvas.drawCircle(
            t.position,
            1.6,
            Paint()..color = Colors.white.withOpacity(0.22),
          );
        }
        d += 16;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeroRoutePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// =============================================================================
// Sélecteur de langue FR / AR
// =============================================================================

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.isArabic, required this.onChanged});

  final bool isArabic;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: _CabaLinkColors.deepNight.withOpacity(0.65),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangButton(
              label: CabalinkGuideUi.frSwitch.fr,
              active: !isArabic,
              onTap: isArabic ? onChanged : null,
            ),
            const SizedBox(width: 3),
            _LangButton(
              label: CabalinkGuideUi.arSwitch.ar,
              active: isArabic,
              onTap: isArabic ? null : onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _CabaLinkColors.tagBrass : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: active ? _CabaLinkColors.deepNight : Colors.white70,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Tuiles statistiques (compteurs animés, chiffres LTR)
// =============================================================================

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.decimals,
    required this.unit,
    required this.label,
  });

  final double value;
  final int decimals;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _CabaLinkColors.manifestWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x0A000000)),
        ),
        child: Column(
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: value),
                      duration: const Duration(milliseconds: 1100),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, child) => Text(
                        v.toStringAsFixed(decimals),
                        style: _flapNumberStyle(
                          size: 26,
                          color: _CabaLinkColors.inkNavy,
                        ),
                      ),
                    ),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 3),
                      Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _CabaLinkColors.tagBrass,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                height: 1.2,
                color: _CabaLinkColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Carrousel des rôles
// =============================================================================

class _RolesCarousel extends StatefulWidget {
  const _RolesCarousel();

  @override
  State<_RolesCarousel> createState() => _RolesCarouselState();
}

class _RolesCarouselState extends State<_RolesCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.82);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool ar = Directionality.maybeOf(context) == TextDirection.rtl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          child: _aysSectionHeader(
            isArabic: ar,
            eyebrow: const CabalinkL10n('Les rôles', 'الأدوار'),
            title: CabalinkGuideUi.highlightRoles,
            subtitle: CabalinkGuideUi.highlightRolesSub,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _controller,
            itemCount: cabalinkRoles.length,
            padEnds: true,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _RoleCard(role: cabalinkRoles[index], isArabic: ar),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < cabalinkRoles.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: i == _page
                      ? _CabaLinkColors.tagBrass
                      : _CabaLinkColors.ink.withOpacity(0.18),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.isArabic});

  final CabaLinkRole role;
  final bool isArabic;

  String get _name => role.name.pick(isArabic: isArabic);
  String get _detail => role.shortDescription.pick(isArabic: isArabic);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _CabaLinkColors.manifestWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x0A000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D12213D),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: _CabaLinkColors.inkNavy,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(role.icon, color: _CabaLinkColors.tagBrassLight, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            _name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: _CabaLinkColors.ink,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              _detail,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: _CabaLinkColors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Jauge de poids payé (60 kg / 20 utilisés → 40 disponibles)
// =============================================================================

class _WeightGaugeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const int allowed = kWeightCheckedInKg;
    const int used = kWeightUsedKg;
    const int available = allowed - used;
    const double usedFraction = used / allowed;
    const double availFraction = available / allowed;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E1B33), Color(0xFF1D3A52)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2617213D),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: available.toDouble()),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Text(
                  value.toStringAsFixed(0),
                  style: _flapNumberStyle(
                    size: 54,
                    color: _CabaLinkColors.tagBrassLight,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${CabalinkGuideUi.weightAvailableLabel.fr} / ${CabalinkGuideUi.weightAvailableOf.fr}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 18,
              child: Row(
                children: [
                  Expanded(
                    flex: _clampedFlex(usedFraction * 1000),
                    child: Container(color: Colors.white.withOpacity(0.14)),
                  ),
                  Expanded(
                    flex: _clampedFlex(availFraction * 1000),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) => DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _CabaLinkColors.tagBrass.withOpacity(value),
                              _CabaLinkColors.tagBrassLight.withOpacity(value),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              _legendDot(
                Colors.white.withOpacity(0.3),
                CabalinkGuideUi.weightAlreadyUsed.fr,
              ),
              _legendDot(
                _CabaLinkColors.tagBrass,
                CabalinkGuideUi.weightToPublish.fr,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _legendDot(Color color, String label) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFFB9C2CE)),
      ),
    ],
  );
}

// =============================================================================
// Simulateur de commission (chiffres et contrôle en LTR)
// =============================================================================

class _CommissionSimulator extends StatefulWidget {
  const _CommissionSimulator();

  @override
  State<_CommissionSimulator> createState() => _CommissionSimulatorState();
}

class _CommissionSimulatorState extends State<_CommissionSimulator> {
  double _pricePerKg = kSimDefaultPriceDzd;
  double _weightKg = kSimDefaultWeightKg.toDouble();
  bool _ambassador = false;

  int get _priceDivisions =>
      ((kSimMaxPriceDzd - kSimMinPriceDzd) / kSimStepPriceDzd).round();

  double get _commissionTotalDzd =>
      _weightKg * kCabaLinkCommissionPerKg * kCabaLinkRateDzd;
  double get _ambassadorTotalDzd =>
      _weightKg * kAmbassadorSharePerKg * kCabaLinkRateDzd;
  double get _transporterTotalDzd => _weightKg * _pricePerKg;
  double get _finalPerKg => _pricePerKg + kCabaLinkCommissionDzdPerKg();
  double get _finalTotal => _transporterTotalDzd + _commissionTotalDzd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _CabaLinkColors.manifestWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x0A000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D12213D),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sliderRow(
            label: CabalinkGuideUi.simTransporterPrice.fr,
            valueLabel: '${_formatNumber(_pricePerKg)} DZD/kg',
            value: _pricePerKg,
            min: kSimMinPriceDzd,
            max: kSimMaxPriceDzd,
            divisions: _priceDivisions,
            onChanged: (v) => setState(() => _pricePerKg = v),
          ),
          const SizedBox(height: 8),
          _sliderRow(
            label: CabalinkGuideUi.simWeight.fr,
            valueLabel: '${_formatNumber(_weightKg)} kg',
            value: _weightKg,
            min: kSimMinWeightKg.toDouble(),
            max: kSimMaxWeightKg.toDouble(),
            divisions: kSimMaxWeightKg - kSimMinWeightKg,
            onChanged: (v) => setState(() => _weightKg = v),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  CabalinkGuideUi.simAmbassadorTrip.fr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _CabaLinkColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(CabalinkGuideUi.simNo.fr),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(CabalinkGuideUi.simYes.fr),
                  ),
                ],
                selected: {_ambassador},
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
                onSelectionChanged: (selection) =>
                    setState(() => _ambassador = selection.first),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_ambassador) ...[
            _amountLine(
              label: CabalinkGuideUi.simAmbassadorShare.fr,
              valueDzd: _ambassadorTotalDzd,
            ),
            const SizedBox(height: 8),
          ],
          _amountLine(
            label: CabalinkGuideUi.simCommissionLabel.fr,
            valueDzd: _commissionTotalDzd,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0E1B33), Color(0xFF1D3A52)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(
                  CabalinkGuideUi.simFinalPrice.fr,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.72),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _finalTotal),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) => Text(
                        _formatNumber(value),
                        style: _flapNumberStyle(
                          size: 30,
                          color: _CabaLinkColors.tagBrassLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'DZD',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatNumber(_finalPerKg)} DZD/kg',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            CabalinkGuideUi.simNoteTransporter.fr,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: _CabaLinkColors.inkMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CabalinkGuideUi.simNoteRate.fr,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: _CabaLinkColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _CabaLinkColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              valueLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _CabaLinkColors.tagBrass,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _CabaLinkColors.inkNavy,
            thumbColor: _CabaLinkColors.inkNavy,
            inactiveTrackColor: _CabaLinkColors.inkNavy.withOpacity(0.1),
            overlayColor: _CabaLinkColors.inkNavy.withOpacity(0.1),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _amountLine({required String label, required double valueDzd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _CabaLinkColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_formatNumber(valueDzd)} DZD',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: _CabaLinkColors.inkNavy,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Carte d'embarquement ambassadeur
// =============================================================================

class _AmbassadorPass extends StatelessWidget {
  const _AmbassadorPass();

  @override
  Widget build(BuildContext context) {
    final bool ar = Directionality.maybeOf(context) == TextDirection.rtl;
    return Container(
      decoration: BoxDecoration(
        color: _CabaLinkColors.manifestWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x0A000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D12213D),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 264,
        child: Stack(
        children: [
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            width: 96,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0E1B33), Color(0xFF1D3A52)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      Text(
                        CabalinkGuideUi.ambassadorCode.pick(isArabic: ar),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'CBK-AMBASS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _CabaLinkColors.tagBrassLight,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: _CabaLinkColors.tagBrass,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.card_giftcard,
                            color: _CabaLinkColors.deepNight,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          CabalinkGuideUi.ambassadorShareKg.pick(isArabic: ar),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            start: 97,
            top: 0,
            bottom: 0,
            width: 1,
            child: Container(color: _CabaLinkColors.ink.withOpacity(0.06)),
          ),
          Positioned.fill(
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 118,
                top: 18,
                end: 18,
                bottom: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CabalinkGuideUi.ambassadorYou.pick(isArabic: ar),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _CabaLinkColors.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Directionality(
                    textDirection: TextDirection.ltr,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        '1 €/kg pour l’ambassadeur · 1 €/kg pour CabaLink · 2 €/kg au total',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: _CabaLinkColors.altitudeTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CabalinkGuideUi.ambassadorActivity.pick(isArabic: ar),
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: _CabaLinkColors.inkMuted,
                    ),
                  ),
],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

// =============================================================================
// Grille des principes (point 39)
// =============================================================================

class _PrincipleTile extends StatelessWidget {
  const _PrincipleTile({required this.principle, required this.isArabic});

  final CabaLinkPrinciple principle;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _CabaLinkColors.manifestWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x0A000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            principle.icon,
            color: _CabaLinkColors.inkNavy,
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            principle.name.pick(isArabic: isArabic),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: _CabaLinkColors.ink,
            ),
          ),
const SizedBox(height: 3),
          Expanded(
            child: Text(
            principle.detail.pick(isArabic: isArabic),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.3,
              color: _CabaLinkColors.inkMuted,
            ),
          ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Chapitre du guide (ExpansionTile) + rendu des blocs
// =============================================================================

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({required this.section, required this.isArabic});

  final CabalinkGuideSection section;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final String title = isArabic ? section.aTitle : section.fTitle;
    final List<CabalinkGuideBlock> blocks =
        isArabic ? section.aBlocks : section.fBlocks;
    final bool isConclusion = section.number == cabalinkGuideSections.length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConclusion
              ? _CabaLinkColors.tagBrass.withOpacity(0.5)
              : const Color(0x0A000000),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          collapsedShape: const RoundedRectangleBorder(),
          backgroundColor: isConclusion
              ? _CabaLinkColors.tagBrass.withOpacity(0.05)
              : _CabaLinkColors.manifestWhite,
          collapsedBackgroundColor: isConclusion
              ? _CabaLinkColors.tagBrass.withOpacity(0.05)
              : _CabaLinkColors.manifestWhite,
          iconColor: _CabaLinkColors.inkNavy,
          collapsedIconColor: _CabaLinkColors.inkMuted,
          leading: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isConclusion
                  ? _CabaLinkColors.tagBrass
                  : _CabaLinkColors.inkNavy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${section.number}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isConclusion
                    ? _CabaLinkColors.deepNight
                    : _CabaLinkColors.manifestWhite,
              ),
            ),
          ),
          title: Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: _CabaLinkColors.ink,
              height: 1.25,
            ),
          ),
          children: [
            _ChapterBlocks(blocks: blocks, isArabic: isArabic),
          ],
        ),
      ),
    );
  }
}

class _ChapterBlocks extends StatelessWidget {
  const _ChapterBlocks({required this.blocks, required this.isArabic});

  final List<CabalinkGuideBlock> blocks;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < blocks.length; i++) ...[
          _ChapterBlockWidget(block: blocks[i], isArabic: isArabic),
          if (i < blocks.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ChapterBlockWidget extends StatelessWidget {
  const _ChapterBlockWidget({required this.block, required this.isArabic});

  final CabalinkGuideBlock block;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      GuideParagraph(:final text) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: _CabaLinkColors.ink,
            ),
          ),
        ),
      GuideBullets(:final items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: _CabaLinkColors.tagBrass,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: _CabaLinkColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      GuideSteps(:final items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _CabaLinkColors.inkNavy.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _CabaLinkColors.inkNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          items[i],
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: _CabaLinkColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      GuideQuote(:final text) => Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: _CabaLinkColors.manifestPaper,
            borderRadius: BorderRadius.circular(14),
            border: BorderDirectional(
              start: BorderSide(
                color: _CabaLinkColors.tagBrass.withOpacity(0.6),
                width: 3,
              ),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: _CabaLinkColors.inkMuted,
            ),
          ),
        ),
      GuideFormula(:final lines) => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _CabaLinkColors.inkNavy,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    line,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          ),
        ),
      GuideTable(:final headers, :final rows) => _GuideTableWidget(
          headers: headers,
          rows: rows,
        ),
      GuideDiagram(:final steps) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _CabaLinkColors.manifestWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x14000000)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}.',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _CabaLinkColors.tagBrass,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: _CabaLinkColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 3),
                  child: Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      color: _CabaLinkColors.inkMuted,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ],
        ),
    };
  }
}

class _GuideTableWidget extends StatelessWidget {
  const _GuideTableWidget({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14000000)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(1),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder.all(
          color: const Color(0x14000000),
          width: 1,
        ),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: _CabaLinkColors.inkNavy),
            children: [
              for (final h in headers)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  child: Text(
                    h,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          for (final row in rows)
            TableRow(
              children: [
                for (final cell in row)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Text(
                      cell,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: _CabaLinkColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

