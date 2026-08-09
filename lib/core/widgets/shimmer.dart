import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A shimmer skeleton used as a lazy placeholder while lists load.
///
/// Build shimmer blocks inside a `SliverList` / `SliverGrid` so the loading
/// state itself stays lazy and cheap.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppTheme.radiusXs,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Alignment> _alignment;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _alignment = Tween<Alignment>(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _alignment,
      builder: (context, _) {
        return Align(
          alignment: _alignment.value,
          child: FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                shape: widget.shape,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.surfaceMuted,
                    Colors.white,
                    AppTheme.surfaceMuted,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A full card-shaped skeleton (image + lines) for list items.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({
    super.key,
    this.imageHeight = 120,
    this.lines = 3,
  });

  final double imageHeight;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      decoration: AppTheme.cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: double.infinity, height: imageHeight, radius: 0),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 180, height: 18),
                const SizedBox(height: AppTheme.spaceSm),
                for (var i = 0; i < lines; i++) ...[
                  ShimmerBox(width: 40 + (i * 25).toDouble(), height: 12),
                  const SizedBox(height: AppTheme.spaceSm),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
