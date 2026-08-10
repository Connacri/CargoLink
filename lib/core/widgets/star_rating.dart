import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Displays a read-only star rating (e.g. on a shipper's public profile).
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.size = 18,
    this.color = Colors.amber,
  });

  final double rating;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final icon = rating >= index + 1
            ? Icons.star_rounded
            : (rating > index
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded);
        return Icon(icon, size: size, color: color);
      }),
    );
  }
}

/// Interactive star picker used by the client to rate a shipper after delivery.
class StarPicker extends StatelessWidget {
  const StarPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final selected = index < value;
        return GestureDetector(
          onTap: () => onChanged(index + 1),
          child: AnimatedScale(
            scale: selected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Icon(
              selected ? Icons.star_rounded : Icons.star_border_rounded,
              size: size,
              color: selected ? Colors.amber : AppTheme.textMutedColor,
            ),
          ),
        );
      }),
    );
  }
}
