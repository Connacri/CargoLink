import 'package:flutter/material.dart';

/// Wraps a child and animates it in with a slide + fade when it first appears.
///
/// Pass [delay] (e.g. `index * 50ms`) to create a staggered cascade when used
/// inside a list/grid of items.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 24),
    this.duration = const Duration(milliseconds: 420),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Offset offset;
  final Duration duration;
  final Curve curve;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _position;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _position = Tween<Offset>(begin: widget.offset, end: Offset.zero)
        .animate(curved);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _position, child: widget.child),
    );
  }
}

/// A single-line animated icon that pulses softly. Placeholder for richer icons.
class AnimatedIconDot extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      width: size + 14,
      height: size + 14,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}
