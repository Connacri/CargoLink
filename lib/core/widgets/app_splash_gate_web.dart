import 'package:flutter/widgets.dart';

class FasSplashConfig {
  const FasSplashConfig();
}

const FasSplashConfig fasSplash = FasSplashConfig();

class AdaptiveSplash extends StatelessWidget {
  const AdaptiveSplash({
    super.key,
    required this.child,
    this.config,
    this.ready,
    this.force,
  });

  final FasSplashConfig? config;
  final Widget child;
  final Future<void>? ready;
  final bool? force;

  @override
  Widget build(BuildContext context) => child;
}

class FasNativeSplash {
  FasNativeSplash._();

  static void preserve({
    required WidgetsBinding widgetsBinding,
    Duration? maxDuration,
  }) {}

  static void remove() {}
}
