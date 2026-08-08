import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'data/services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (for notifications)
  await initializeFirebase();

  // Wire Firebase Cloud Messaging
  await FcmService.instance.init();

  runApp(const ProviderScope(child: CargoLinkApp()));
}
