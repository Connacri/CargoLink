import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// One slide of a [WorkflowSlider]: a title, a subtitle and numbered steps
/// plus optional key rules.
class WorkflowSlide {
  const WorkflowSlide({
    required this.title,
    required this.steps,
    this.subtitle,
    this.rules = const [],
    this.icon,
    this.gradient,
  });

  final String title;
  final String? subtitle;
  final List<String> steps;
  final List<String> rules;
  final IconData? icon;
  final LinearGradient? gradient;
}

/// A reusable swipeable carousel ("slider") presenting a sequence of
/// [WorkflowSlide]s with a pager indicator. Follows the CargoLink design
/// tokens and uses [AppTheme] gradients/radii/spacing.
class WorkflowSlider extends StatefulWidget {
  const WorkflowSlider({
    super.key,
    required this.slides,
    this.height = 300,
    this.pageController,
    this.onPageChanged,
  });

  final List<WorkflowSlide> slides;
  final double height;
  final PageController? pageController;
  final ValueChanged<int>? onPageChanged;

  @override
  State<WorkflowSlider> createState() => _WorkflowSliderState();
}

class _WorkflowSliderState extends State<WorkflowSlider> {
  late final PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.pageController ?? PageController();
  }

  @override
  void dispose() {
    if (widget.pageController == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.slides.length,
            onPageChanged: (index) {
              setState(() => _current = index);
              widget.onPageChanged?.call(index);
            },
            itemBuilder: (context, index) =>
                _SlideCard(slide: widget.slides[index]),
          ),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        _Dots(count: widget.slides.length, current: _current),
      ],
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.slide});

  final WorkflowSlide slide;

  @override
  Widget build(BuildContext context) {
    final gradient = slide.gradient ?? AppTheme.primaryGradient;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSm),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowLg,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Icon(
              slide.icon ?? Icons.auto_awesome_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          // Scrollable : tolère les contenus longs (titre + étapes + règles)
          // quelle que soit la hauteur imposée par l'écran appelant.
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                Text(
                  slide.title,
                  style: AppTheme.h2.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                if (slide.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    slide.subtitle!,
                    style: AppTheme.bodySecondary
                        .copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                  ),
                ],
                const SizedBox(height: AppTheme.spaceMd),
                ...List.generate(slide.steps.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceSm),
                        Expanded(
                          child: Text(
                            slide.steps[i],
                            style: AppTheme.body.copyWith(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (slide.rules.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spaceXs),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceSm),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Règles clés',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final rule in slide.rules)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '• $rule',
                              style: AppTheme.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: active ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.primaryColor
                : AppTheme.textMutedColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}