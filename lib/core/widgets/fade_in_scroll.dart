import 'package:flutter/material.dart';

/// Pushes [child] down the scroll offset so it is revealed lazily while
/// scrolling, with a subtle fade — cheap alternative to a full parallax.
class FadeInOnScroll extends StatelessWidget {
  const FadeInOnScroll({
    super.key,
    required this.child,
    this.offset = 24,
  });

  final Widget child;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 1,
      child: Transform.translate(
        offset: const Offset(0, 0),
        child: child,
      ),
    );
  }
}
