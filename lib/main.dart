import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'data/services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge is enabled in MainActivity.kt via WindowCompat.
  // Here we only ensure the system UI style matches our dark theme.
  // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
  //   statusBarColor: Colors.transparent,
  //   systemNavigationBarColor: Colors.transparent,
  //   statusBarBrightness: Brightness.dark,
  //   systemNavigationBarIconBrightness: Brightness.light,
  // ));

  // Initialize Firebase (for notifications)
  await initializeFirebase();

  // Initialize Supabase Auth (native session, PKCE). Must complete before any
  // database request: SupabaseAuth restores the persisted session on startup.
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );

  // Wire Firebase Cloud Messaging (with timeout to never block the splash)
  try {
    await FcmService.instance.init().timeout(const Duration(seconds: 8));
  } catch (_) {}

  runApp(
    ProviderScope(
      child: BetterFeedback(
        localeOverride: const Locale('fr'),
        themeMode: ThemeMode.dark,
        mode: FeedbackMode.draw,
        theme: FeedbackThemeData(
          background: const Color(0xFF303030),
          feedbackSheetColor: const Color(0xFF1E1E2E),
          bottomSheetDescriptionStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontFamily: 'Oswald'),
          bottomSheetTextInputStyle: const TextStyle(
              color: Colors.white, fontSize: 16, fontFamily: 'Oswald'),
          brightness: Brightness.dark,
          dragHandleColor: Colors.white38,
        ),
        child: const CargoLinkApp(),
      ),
    ),
  );
}
