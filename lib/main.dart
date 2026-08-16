import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'data/services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fullscreen (hide status & navigation bars) once the Flutter UI renders
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Firebase (for notifications)
  await initializeFirebase();

  // Wire Firebase Cloud Messaging
  await FcmService.instance.init();

  runApp(
    const ProviderScope(
      child: BetterFeedback(
        localeOverride: Locale('fr'),
        themeMode: ThemeMode.dark,
        mode: FeedbackMode.draw,
        child: CargoLinkApp(),
      ),
    ),
  );
}
