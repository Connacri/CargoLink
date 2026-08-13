import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// A lightweight, dependency-free bar chart used to visualize revenue.
///
/// Each [RevenueBar] maps to a label + a value; bars are scaled relative to
/// the max value. Purely visual — no chart package required.
class RevenueBar {
  const RevenueBar({required this.label, required this.value});

  final String label;
  final double value;
}

class RevenueBarChart extends StatelessWidget {
  const RevenueBarChart({
    super.key,
    required this.data,
    this.height = 140,
    this.color = AppTheme.accentColor,
    this.valueFormatter,
  });

  final List<RevenueBar> data;
  final double height;
  final Color color;

  /// Formats the value shown above each bar (e.g. "3.6k").
  final String Function(double value)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Pas encore de données sur cette période',
            style: AppTheme.bodySecondary,
          ),
        ),
      );
    }

    final maxValue = data.fold<double>(0, (m, d) => d.value > m ? d.value : m);
    final effectiveMax = maxValue == 0 ? 1.0 : maxValue;

    // Leave ~22px headroom for the value + month labels above/below the bars.
    final barSpace = (height - 22).clamp(0.0, height);

    return SizedBox(
      height: height + 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bar in data)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (bar.value > 0)
                      Text(
                        valueFormatter?.call(bar.value) ??
                            bar.value.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppTheme.textMutedColor,
                        ),
                      ),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      height: (bar.value / effectiveMax) * barSpace,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bar.label,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.textSecondaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
