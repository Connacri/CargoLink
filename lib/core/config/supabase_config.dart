import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, SupabaseClient;

import 'firebase_options.dart';

// ============================================================================
// SUPABASE CONFIGURATION (Auth natif Supabase)
// ============================================================================

class SupabaseConfig {
  // Project URL (public, safe to commit)
  static const String supabaseUrl = 'https://mxhomeuraxnmjtfhzhvz.supabase.co';

  // Anon (publishable) key. It is public by design, so the real project key is
  // baked in as the default (works in local runs). CI may still override it via
  // --dart-define=SUPABASE_ANON_KEY=...
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im14aG9tZXVyYXhubWp0Zmh6aHZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYwNDMyODIsImV4cCI6MjEwMTYxOTI4Mn0.'
        'phNESFfG1i7Xd-Z_oc_xTEX14KIL7rVGUyHJzkwKDHw',
  );

  /// The Publishable API key (supabase-js v2 style), if used.
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  /// Client global BACKED BY SupabaseAuth natif : le SDK restaure la session
  /// persistée au démarrage et attache automatiquement le jeton d'accès à
  /// chaque requête (RLS sur `auth.uid()`). Doit être initialisé via
  /// `Supabase.initialize(...)` dans `main()` avant toute requête.
  static SupabaseClient get client => Supabase.instance.client;

  /// URL de retour des liens d'email (confirmation d'inscription,
  /// réinitialisation de mot de passe) :
  ///  - mobile : deep link custom scheme qui ré-ouvre l'app et complète le
  ///    flux PKCE (SupabaseAuth l'écoute automatiquement via app_links) ;
  ///  - web    : l'application hébergée, qui termine le flux PKCE dans
  ///    l'onglet (detectSessionInUri).
  static String get authRedirectUrl => kIsWeb
      ? 'https://connacri.github.io/CargoLink/'
      : 'com.cargolink.dz.cargolink://login-callback';
}

// ============================================================================
// FIREBASE CONFIGURATION (conservé pour les notifications FCM uniquement)
// ============================================================================

Future<void> initializeFirebase() async {
  // Suppress "USE_AUTH_EMULATOR not set" info log from Firebase Auth SDK.
  await runZonedGuarded(
    () => Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    (error, stack) {},
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        if (!line.contains('USE_AUTH_EMULATOR')) {
          parent.print(self, line);
        }
      },
    ),
  );
}