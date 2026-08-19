import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';

// ============================================================================
// SUPABASE CONFIGURATION
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

  // Single client, created once. The current (Firebase-issued) JWT is provided
  // through the `accessToken` callback (the documented way to bridge a
  // third-party auth system with Supabase): every request carries it as the
  // `Authorization` header while it is non-null, and falls back to the anon key
  // when signed out.
  static final SupabaseClient _client = SupabaseClient(
    supabaseUrl,
    supabaseAnonKey,
    accessToken: () async => _supabaseJwt,
  );

  static String? _supabaseJwt;

  static SupabaseClient get client => _client;

  /// Whether a Firebase-minted access token is currently active. When false,
  /// every request falls back to the anon key and RLS (`auth.uid() = id`)
  /// silently hides ALL rows — callers that must distinguish "no profile" from
  /// "no session yet" (e.g. the account gate) must check this first, otherwise
  /// an existing user looks like a brand-new one and lands on the role picker.
  static bool get hasAccessToken => _supabaseJwt != null;

  /// Point the app's Supabase client at the (Firebase-minted) token, so every
  /// CRUD is authorized as the authenticated (RLS: auth.uid()) user.
  ///
  /// Also forwards the new JWT to the realtime socket. Without this, an
  /// existing channel keeps its now-stale token and the server closes the
  /// socket (close code 1002) once the previous token expires — which is the
  /// source of the "RealtimeSubscribeException(channelError)" surfaced in the
  /// notifications bottom sheet. Best-effort: never blocks the auth flow.
  static void setAccessToken(String jwt) {
    _supabaseJwt = jwt;
    try {
      _client.realtime.setAuth(jwt);
    } catch (e) {
      // ignore: best-effort realtime re-auth
    }
  }

  /// Reset to the public (anon) client — used on sign-out so that no
  /// authenticated CRUD can be performed afterwards.
  static void reset() {
    _supabaseJwt = null;
  }
}

// ============================================================================
// FIREBASE CONFIGURATION
// ============================================================================

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
