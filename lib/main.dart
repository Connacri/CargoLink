import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'core/widgets/app_splash_gate.dart';
import 'data/services/fcm_service.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Keeps the native splash on screen while startup work runs (no white flash)
  FasNativeSplash.preserve(
    widgetsBinding: binding,
    maxDuration: const Duration(seconds: 10),
  );

  // Fullscreen (hide status & navigation bars) once the Flutter UI renders
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  try {
    // Initialize Firebase (for notifications)
    await initializeFirebase();

    // Wire Firebase Cloud Messaging
    await FcmService.instance.init();

    runApp(
      ProviderScope(
        child: BetterFeedback(
          localeOverride: const Locale('fr'),
          themeMode: ThemeMode.dark,
          mode: FeedbackMode.draw,
          child: AdaptiveSplash(config: fasSplash, child: const CargoLinkApp()),
        ),
      ),
    );
  } finally {
    FasNativeSplash.remove();
  }
}
