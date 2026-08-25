import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fbauth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../../core/config/supabase_config.dart';
import './fcm_service.dart';

// ============================================================================
// FIREBASE -> SUPABASE ID MAPPING
// ============================================================================

// Supabase stores every user row keyed by `users.id` (a UUID) and protects it
// with RLS on `auth.uid()`. A Firebase UID is not a valid UUID, so we map it
// deterministically to a UUID (UUID v5). The same derivation is implemented by
// the `auth-exchange-firebase` Edge Function, so the JWT it mints (whose `sub`
// == this UUID) always matches `users.id` / `shippers.user_id` / etc.
const _uidNamespace = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';
const _uidNamePrefix = 'cargolink:';

// NOTE: in the `uuid` package v4+ the signature is `v5(namespace, name)`
// (namespace FIRST). Passing them reversed throws
// `FormatException: The provided UUID is invalid.`
String supabaseUserIdFromFirebase(String firebaseUid) =>
    const Uuid().v5(_uidNamespace, '$_uidNamePrefix$firebaseUid');

// ============================================================================
// APP AUTH STATE
// ============================================================================

class AppAuthState {
  final String? firebaseUid;
  final String? userId; // deterministic Supabase user id
  final bool emailVerified;

  const AppAuthState(
      {this.firebaseUid, this.userId, this.emailVerified = false});

  bool get isSignedIn => firebaseUid != null;
}

/// Result of a Google sign-in. `isNewUser` is true when the Firebase user has
/// no CargoLink profile yet (first sign-in), in which case the UI must ask the
/// user to pick a role before entering the app.
class GoogleSignInResult {
  final bool isNewUser;
  final String? email;
  final String? fullName;
  final String? photoUrl;
  final String? phone;

  const GoogleSignInResult({
    required this.isNewUser,
    this.email,
    this.fullName,
    this.photoUrl,
    this.phone,
  });
}

// ============================================================================
// AUTH SERVICE (FirebaseAuth + Supabase session)
// ============================================================================

class AuthService {
  AuthService({fbauth.FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? fbauth.FirebaseAuth.instance,
        _logger = Logger() {
    // Le jeton Supabase échangé vit ~1 h : on branche le mécanisme
    // d'auto-refresh de SupabaseConfig sur notre Edge Function d'échange pour
    // qu'aucune requête ne parte avec un « JWT expired » (PGRST303) après une
    // heure de session ouverte.
    SupabaseConfig.setTokenRefresher(_refreshSupabaseToken);
  }

  final fbauth.FirebaseAuth _auth;
  final Logger _logger;

  fbauth.FirebaseAuth get firebaseAuth => _auth;

  /// Re-exchange un ID token Firebase frais contre un nouveau jeton Supabase.
  /// Appelé par [SupabaseConfig._resolveAccessToken] quand le jeton courant
  /// approche son expiration. Lève si l'utilisateur s'est déconnecté.
  Future<String> _refreshSupabaseToken() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Utilisateur déconnecté');
    final token = await _exchangeForSupabaseToken(user);
    SupabaseConfig.setAccessToken(token);
    return token;
  }

  /// Stream of authentication state. Yields the initial state immediately, then
  /// follows FirebaseAuth's `authStateChanges`. Every emitted signed-in user
  /// triggers an exchange of the Firebase ID token for a Supabase access token
  /// (minted by the `auth-exchange-firebase` Edge Function) BEFORE the signed-in
  /// state is emitted, so no downstream call can race ahead of the token swap.
  Stream<AppAuthState> get authStateChanges async* {
    final current = _auth.currentUser;
    if (current != null) {
      try {
        // 20 s total budget for the token exchange (includes 1 retry).
        await _onAuthenticated(current).timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            _logger.e('Token exchange timed out at startup');
          },
        );
      } catch (e) {
        _logger.e('Failed to restore Supabase session: $e');
      }
      // If the exchange failed / timed-out, SupabaseConfig.hasAccessToken is
      // still false. Sign the user out so they land on the login screen
      // instead of being stuck in an infinite gate-retry loop.
      if (!SupabaseConfig.hasAccessToken) {
        try {
          await _auth.signOut();
        } catch (_) {}
        yield const AppAuthState();
        return;
      }
    }
    yield _buildState();

    // Listen to idTokenChanges rather than authStateChanges so that a
    // `reload()` (e.g. after clicking the email verification link) re-emits the
    // state with the fresh `emailVerified` flag.
    await for (final user in _auth.idTokenChanges()) {
      if (user != null) {
        try {
          await _onAuthenticated(user);
        } catch (e) {
          // _logger.e('Failed to exchange Firebase token for Supabase: $e');
        }
      } else {
        SupabaseConfig.reset();
      }
      yield _buildState();
    }
  }

  AppAuthState _buildState() {
    final user = _auth.currentUser;
    if (user == null) return const AppAuthState();
    final userId = supabaseUserIdFromFirebase(user.uid);
    return AppAuthState(
      firebaseUid: user.uid,
      userId: userId,
      emailVerified: user.emailVerified,
    );
  }

  /// Exchange the current Firebase user's ID token for a Supabase access token
  /// (minted by the Edge Function) and point every Supabase call at it.
  ///
  /// Serialized: `authStateChanges` restores the session at startup AND
  /// `idTokenChanges` re-emits the same user immediately, and sign-up/sign-in
  /// also call this — so two exchanges can otherwise run concurrently. For a
  /// brand-new user, two concurrent exchanges both pass the "does the mirror
  /// exist?" check and then both `createUser` with the SAME deterministic id:
  /// the loser gets the GoTrue "Database error creating new user" 500. The edge
  /// function is now race-tolerant too, but never firing the duplicate request
  /// is cleaner. If an exchange is already in-flight, join it.
  Future<void>? _authInFlight;

  Future<void> _onAuthenticated(fbauth.User user) async {
    final inFlight = _authInFlight;
    if (inFlight != null) {
      // _logger.i('_onAuthenticated: joining in-flight exchange');
      await inFlight;
      return;
    }
    final future = _doAuthenticated(user);
    _authInFlight = future;
    try {
      await future;
    } finally {
      _authInFlight = null;
    }
  }

  Future<void> _doAuthenticated(fbauth.User user) async {
    // _logger.i('_onAuthenticated: exchanging Firebase token for Supabase JWT');
    final token = await _exchangeForSupabaseToken(user);
    // _logger.i('_onAuthenticated: received Supabase access token');
    SupabaseConfig.setAccessToken(token);
    final userId = supabaseUserIdFromFirebase(user.uid);
    // _logger.i('_onAuthenticated: supabase userId=$userId');
    await FcmService.instance.registerToken(userId);
    // _logger.i('_onAuthenticated: FCM token registered');
  }

  Future<String> _exchangeForSupabaseToken(fbauth.User user) async {
    // _logger.i('_exchange: fetching fresh Firebase idToken');
    final idToken = await user.getIdToken(true);
    // _logger.i(
    //   '_exchange: posting to auth-exchange-firebase '
    //   '(idToken.length=${idToken?.length ?? 0})',
    // );
    final response = await http.post(
      Uri.parse(
        '${SupabaseConfig.supabaseUrl}/functions/v1/auth-exchange-firebase',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    ).timeout(const Duration(seconds: 20));
    // _logger.i('_exchange: HTTP ${response.statusCode}');

    if (response.statusCode != 200) {
      _logger.e('_exchange: failed response body=${response.body}');
      throw Exception(
        'Échec de l\'échange de session (${response.statusCode}): '
        '${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = data['accessToken'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Session Supabase indisponible');
    }
    return accessToken;
  }

  // ==========================================================================
  // AUTHENTICATION METHODS
  // ==========================================================================

  /// Sign up with email and password (Firebase), then link the profile.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role, // client or shipper
  }) async {
    try {
      _logger.i('=== Email sign-up === email=$email role=$role');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Création du compte impossible');
      }
      _logger.i('signUp: Firebase user created uid=${user.uid}');

      await user.updateDisplayName(fullName);
      _logger.i('signUp: displayName set to $fullName');

      // Ask Firebase to send the verification email. When the app restarts and
      // the user signs in, authState will carry emailVerified and the router
      // will keep showing the verification page until the user clicks the link.
      if (!user.emailVerified) {
        _logger.i('signUp: email not verified, sending verification email');
        await _sendVerificationEmail(user);
        _logger.i('signUp: verification email sent');
      }

      await _onAuthenticated(user);

      await _createUserProfile(
        userId: supabaseUserIdFromFirebase(user.uid),
        email: email,
        fullName: fullName,
        phone: phone,
        role: role,
      );

      _logger.i('signUp: SUCCESS uid=${user.uid}');
    } on fbauth.FirebaseAuthException catch (e) {
      _logger.e('Sign up error: ${e.message} (code ${e.code})');
      throw AuthServiceException(e.message ?? 'Erreur d\'inscription');
    } catch (e) {
      _logger.e('Unexpected error during sign up: $e');
      rethrow;
    }
  }

  /// Sign in with email and password (Firebase).
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('=== Email sign-in ===');
      _logger.i('signInWithEmail: email=$email');
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = _auth.currentUser;
      if (user == null) throw Exception('Connexion impossible');
      _logger.i('signInWithEmail: Firebase auth OK uid=${user.uid}');

      await _onAuthenticated(user);
      await _ensureProfileIfAbsent(user, email: email);

      _logger.i('signInWithEmail: SUCCESS');
    } on fbauth.FirebaseAuthException catch (e) {
      _logger.e('Email sign-in error: ${e.message} (code ${e.code})');
      throw AuthServiceException(e.message ?? 'Erreur de connexion');
    } catch (e) {
      _logger.e('Unexpected error during email sign in: $e');
      rethrow;
    }
  }

  /// Sign in with Google (Firebase).
  ///
  /// Platform-aware:
  ///  - Web: uses the Firebase `signInWithPopup(GoogleAuthProvider)` flow (the
  ///    `google_sign_in` plugin is discouraged on the web and cannot reliably
  ///    provide an `idToken`, which caused "null check operator used on a null
  ///    value").
  ///  - Android / iOS / macOS: uses `google_sign_in` v6 `signIn()` (the pattern
  ///    proven to work on devices) and exchanges accessToken + idToken.
  ///  - Windows / Linux: `google_sign_in` has no implementation and
  ///    `signInWithPopup` is web-only, so a clear error is raised instead.
  ///
  /// Returns [GoogleSignInResult]. When `isNewUser` is true, no profile row
  /// exists yet: the caller must let the user choose a role and create the
  /// profile (via [createProfileWithRole]) before entering the app.
  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      _logger.i('=== Google sign-in ===');
      _logger.i(
        'Platform: ${kIsWeb ? 'web' : defaultTargetPlatform.name}',
      );

      if (kIsWeb) {
        _logger.i(
            'Web: starting FirebaseAuth.signInWithPopup(GoogleAuthProvider)');
        // Force the account chooser on every sign-in. Without
        // `prompt: select_account`, Google Identity Services silently reuses
        // the last authenticated account, so after a sign-out a user trying to
        // re-auth with a different Google account ends up back on the previous
        // one.
        final provider = fbauth.GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        final userCredential = await _auth.signInWithPopup(provider);
        _logger.i(
          'Web: popup returned uid=${userCredential.user?.uid} '
          'email=${userCredential.user?.email}',
        );
      } else if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux) {
        _logger.e(
          'Google sign-in unsupported on ${defaultTargetPlatform.name}',
        );
        throw AuthServiceException(
          'Google Sign-In n\'est pas encore disponible sur '
          '${defaultTargetPlatform.name}. Utilisez email/mot de passe ou '
          'l\'application mobile.',
        );
      } else {
        _logger.i('Mobile: starting GoogleSignIn().signIn()');
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          _logger.w('Mobile: user cancelled the Google dialog');
          throw AuthServiceException('Connexion Google annulée');
        }
        _logger.i('Mobile: Google account email=${googleUser.email}');
        final googleAuth = await googleUser.authentication;
        _logger.i(
          'Mobile: got idToken=${googleAuth.idToken != null} '
          'accessToken=${googleAuth.accessToken != null}',
        );
        final credential = fbauth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        _logger.i('Mobile: calling FirebaseAuth.signInWithCredential');
        await _auth.signInWithCredential(credential);
        _logger.i('Mobile: FirebaseAuth.signInWithCredential OK');
      }

      final user = _auth.currentUser;
      if (user == null) {
        _logger.e('Google sign-in: currentUser is null after auth');
        throw Exception('Connexion Google impossible');
      }
      _logger.i(
        'Google sign-in: Firebase user uid=${user.uid} email=${user.email}',
      );

      await _onAuthenticated(user);
      _logger.i('Google sign-in: Supabase session + FCM token ready');

      // First-time detection: no profile row means the user must pick a role.
      final existing = await getCurrentUserProfile();
      final isNewUser = existing == null;
      if (isNewUser) {
        _logger.i('Google sign-in: NEW user, role must be chosen');
        return GoogleSignInResult(
          isNewUser: true,
          email: user.email,
          fullName: user.displayName,
          photoUrl: user.photoURL,
          phone: user.phoneNumber,
        );
      }
      _logger.i(
        'Google sign-in: returning user (role=${existing.role}), SUCCESS',
      );

      // Existing user: attach the Google profile picture and phone number to
      // the CargoLink profile when the account has them (and they are missing
      // locally), so the avatar/phone stay in sync with the Google account.
      final googlePhoto = user.photoURL;
      final googlePhone = user.phoneNumber;
      if ((googlePhoto != null && googlePhoto.isNotEmpty) ||
          (googlePhone != null && googlePhone.isNotEmpty)) {
        try {
          final updateData = <String, dynamic>{
            'updated_at': DateTime.now().toIso8601String(),
          };
          final needsPhoto = (existing.profilePictureUrl == null ||
                  existing.profilePictureUrl!.isEmpty) &&
              googlePhoto != null &&
              googlePhoto.isNotEmpty;
          final needsPhone = existing.phone.isEmpty &&
              googlePhone != null &&
              googlePhone.isNotEmpty;
          if (needsPhoto) updateData['profile_picture_url'] = googlePhoto;
          if (needsPhone) updateData['phone'] = googlePhone;
          if (needsPhoto || needsPhone) {
            await SupabaseConfig.client
                .from('users')
                .update(updateData)
                .eq('id', existing.id);
            _logger.i(
              'Google sign-in: profile synced '
              '(photo=${needsPhoto ? 'yes' : 'no'}, '
              'phone=${needsPhone ? 'yes' : 'no'})',
            );
          }
        } catch (e) {
          _logger.w('Google sign-in: profile sync failed (ignored): $e');
        }
      }

      return const GoogleSignInResult(isNewUser: false);
    } catch (e) {
      _logger.e('Google sign-in FAILED: $e');
      rethrow;
    }
  }

  /// Sign out the current user (Firebase + reset Supabase to anon).
  ///
  /// `GoogleSignIn().signOut()` is only available on mobile (Android / iOS /
  /// macOS). On web and desktop it has no implementation and throws
  /// `MissingPluginException`, so it is guarded by platform and never allowed
  /// to block the sign-out.
  Future<void> signOut() async {
    try {
      _logger.i('=== Sign out ===');
      try {
        await FcmService.instance.clearToken();
        _logger.i('signOut: FCM token cleared');
      } catch (e) {
        _logger.w('signOut: FCM token clear failed (ignored): $e');
      }
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        try {
          await GoogleSignIn().signOut();
          _logger.i('signOut: GoogleSignIn signed out');
        } catch (e) {
          _logger.w('signOut: GoogleSignIn signOut failed (ignored): $e');
        }
      }
      await _auth.signOut();
      _logger.i('signOut: FirebaseAuth signed out');
      SupabaseConfig.reset();
      _logger.i('signOut: Supabase session reset, SUCCESS');
    } catch (e) {
      _logger.e('Sign out error: $e');
      rethrow;
    }
  }

  /// Request a password reset email.
  Future<void> resetPassword(String email) async {
    try {
      _logger.i('=== Password reset === email=$email');
      await _auth.sendPasswordResetEmail(email: email);
      _logger.i('Password reset email sent');
    } on fbauth.FirebaseAuthException catch (e) {
      _logger.e('Reset password error: ${e.message} (code ${e.code})');
      throw AuthServiceException(e.message ?? 'Erreur de réinitialisation');
    } catch (e) {
      _logger.e('Unexpected error during password reset: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // ACCOUNT STATUS (deactivate / delete with 30-day grace period)
  // ==========================================================================

  static const Duration deletionGracePeriod = Duration(days: 30);

  /// Facebook-style deactivation: the profile is flagged inactive, the user is
  /// signed out, but nothing is deleted. The account can be reactivated later.
  Future<void> deactivateAccount() async {
    try {
      _logger.i('=== Deactivate account ===');
      final userId = currentUserId;
      if (userId == null) throw Exception('Aucun utilisateur connecté');
      await SupabaseConfig.client.from('users').update({
        'is_active': false,
        'deactivated_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      _logger.i('Account deactivated');
      await signOut();
    } catch (e) {
      _logger.e('Error deactivating account: $e');
      rethrow;
    }
  }

  /// Reactivate a deactivated account.
  Future<void> reactivateAccount() async {
    try {
      _logger.i('=== Reactivate account ===');
      final userId = currentUserId;
      if (userId == null) throw Exception('Aucun utilisateur connecté');
      await SupabaseConfig.client.from('users').update({
        'is_active': true,
        'deactivated_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      _logger.i('Account reactivated');
    } catch (e) {
      _logger.e('Error reactivating account: $e');
      rethrow;
    }
  }

  /// Request permanent deletion. The account is flagged and the actual deletion
  /// happens after [deletionGracePeriod] (30 days). During that window the user
  /// can log back in and cancel the deletion.
  Future<void> requestAccountDeletion() async {
    try {
      _logger.i('=== Request account deletion ===');
      final userId = currentUserId;
      if (userId == null) throw Exception('Aucun utilisateur connecté');
      await SupabaseConfig.client.from('users').update({
        'is_active': false,
        'deletion_requested_at': DateTime.now().toIso8601String(),
        'deactivated_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      _logger.i('Deletion requested (30-day grace period)');
      await signOut();
    } catch (e) {
      _logger.e('Error requesting deletion: $e');
      rethrow;
    }
  }

  /// Cancel a pending deletion request.
  Future<void> cancelAccountDeletion() async {
    try {
      _logger.i('=== Cancel account deletion ===');
      final userId = currentUserId;
      if (userId == null) throw Exception('Aucun utilisateur connecté');
      await SupabaseConfig.client.from('users').update({
        'is_active': true,
        'deletion_requested_at': null,
        'deactivated_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      _logger.i('Deletion cancelled');
    } catch (e) {
      _logger.e('Error cancelling deletion: $e');
      rethrow;
    }
  }

  /// Whether the deletion grace period has elapsed since the request.
  bool deletionGraceElapsed(DateTime requestedAt) {
    return DateTime.now().difference(requestedAt) >= deletionGracePeriod;
  }

  /// Permanently delete the account now (after the 30-day grace period has
  /// elapsed). Calls the `delete-account` Edge Function which purges every row
  /// (public tables, storage objects), the Supabase auth user and finally the
  /// Firebase account, server-side.
  Future<void> deleteAccountPermanently() async {
    try {
      _logger.i('=== Permanent account deletion ===');
      final user = _auth.currentUser;
      if (user == null) throw Exception('Aucun utilisateur connecté');
      final idToken = await user.getIdToken(true);
      final response = await http.post(
        Uri.parse(
          '${SupabaseConfig.supabaseUrl}/functions/v1/delete-account',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );
      _logger.i('delete-account: HTTP ${response.statusCode}');
      if (response.statusCode != 200) {
        throw Exception(
          'Échec de la suppression (${response.statusCode}): ${response.body}',
        );
      }
      // Account is gone — fully sign out.
      SupabaseConfig.reset();
      await _auth.signOut();
      _logger.i('Account permanently deleted');
    } catch (e) {
      _logger.e('Error deleting account permanently: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // USER PROFILE METHODS
  // ==========================================================================

  /// Get current user ID as the deterministic Supabase UUID.
  String? get currentUserId {
    final user = _auth.currentUser;
    return user == null ? null : supabaseUserIdFromFirebase(user.uid);
  }

  bool get isAuthenticated => _auth.currentUser != null;

  /// Build the action-code settings used for the email verification / password
  /// reset links. `handleCodeInApp: false` lets Firebase's hosted action
  /// handler (https://<project>.firebaseapp.com/__/auth/action) verify the
  /// email server-side and then continue to the deployed web app. The GitHub
  /// Pages domain must be listed in the Firebase console under
  /// Authentication -> Settings -> Authorized domains, otherwise Firebase
  /// rejects the send with INVALID_CONTINUE_URI.
  static final fbauth.ActionCodeSettings _verificationCodeSettings =
      fbauth.ActionCodeSettings(
    url: 'https://connacri.github.io/CargoLink/',
    handleCodeInApp: false,
    androidPackageName: 'com.cargolink.dz.cargolink',
    androidInstallApp: true,
    androidMinimumVersion: '1',
    iOSBundleId: 'com.cargolink.dz.cargolink',
  );

  /// Ask Firebase to send the email-verification link for the given user.
  ///
  /// Tries the app-specific action link first (returns the user to the web app
  /// after verifying). If the continue URL domain is not yet in the Firebase
  /// "Authorized domains" list, Firebase rejects the send with
  /// INVALID_CONTINUE_URI, so we retry with the default action handler — this
  /// guarantees the email always gets dispatched.
  Future<void> _sendVerificationEmail(fbauth.User user) async {
    try {
      await user.sendEmailVerification(_verificationCodeSettings);
      _logger.i('Verification email sent (app action link)');
    } catch (e) {
      _logger.w(
        'Verification email with action settings failed ($e); '
        'retrying with default handler',
      );
      await user.sendEmailVerification();
    }
  }

  /// Re-send the email verification link for the currently signed-in user.
  Future<void> resendVerificationEmail() async {
    try {
      _logger.i('=== Resend verification email ===');
      final user = _auth.currentUser;
      if (user == null) throw Exception('Aucun utilisateur connecté');
      await _sendVerificationEmail(user);
      _logger.i('Verification email re-sent');
    } on fbauth.FirebaseAuthException catch (e) {
      _logger
          .e('Resend verification email error: ${e.message} (code ${e.code})');
      throw AuthServiceException(e.message ?? 'Erreur d\'envoi');
    } catch (e) {
      _logger.e('Unexpected error while resending verification email: $e');
      rethrow;
    }
  }

  /// Reload the Firebase user and return whether the email is verified now.
  Future<bool> refreshEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      await user.reload();
      return user.emailVerified;
    } catch (e) {
      _logger.e('Error refreshing email verification: $e');
      return _auth.currentUser?.emailVerified ?? false;
    }
  }

  /// Create (idempotent) the user profile in the database. RLS allows the
  /// insert only when `auth.uid() = id`, which holds because the Supabase token
  /// minted for this Firebase user has `sub == id`.
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String fullName,
    required String phone,
    required String role,
    String? profilePictureUrl,
  }) async {
    try {
      await SupabaseConfig.client.from('users').insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'role': role,
        if (profilePictureUrl != null && profilePictureUrl.isNotEmpty)
          'profile_picture_url': profilePictureUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      _logger.i('User profile created in database');
    } catch (e) {
      _logger.e('Error creating user profile: $e');
      rethrow;
    }
  }

  /// If a profile row does not exist yet (e.g. Google sign-in), create a
  /// minimal one so the user can be routed by role. For existing users this is
  /// a safety net; new Google users go through [createProfileWithRole] instead
  /// (so they get to pick their role).
  Future<void> _ensureProfileIfAbsent(fbauth.User user, {String? email}) async {
    _logger.i('_ensureProfileIfAbsent: checking users row');
    final existing = await getCurrentUserProfile();
    if (existing != null) {
      _logger
          .i('_ensureProfileIfAbsent: profile exists (role=${existing.role})');
      return;
    }

    try {
      await _createUserProfile(
        userId: supabaseUserIdFromFirebase(user.uid),
        email: email ?? user.email ?? 'user@cargolink.app',
        fullName: user.displayName ??
            ((user.email ?? '').isNotEmpty
                ? user.email!.split('@').first
                : 'Utilisateur'),
        phone: '',
        role: 'client',
        profilePictureUrl: user.photoURL,
      );
      _logger.i('_ensureProfileIfAbsent: profile auto-created');
    } catch (e) {
      _logger.w('Could not auto-create profile: $e');
    }
  }

  /// Create the CargoLink profile for a brand-new user (e.g. first Google
  /// sign-in) with the role they picked. Used by the role-selection flow.
  ///
  /// When the Firebase account carries a Google profile picture or phone
  /// number, they are attached to the profile so a Google sign-in always
  /// restores the avatar and phone number.
  Future<void> createProfileWithRole({
    required String role,
    String? fullName,
    String? phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Aucun utilisateur connecté');
    }
    await _createUserProfile(
      userId: supabaseUserIdFromFirebase(user.uid),
      email: user.email ?? 'user@cargolink.app',
      fullName: fullName ??
          user.displayName ??
          ((user.email ?? '').isNotEmpty
              ? user.email!.split('@').first
              : 'Utilisateur'),
      phone: phone ?? user.phoneNumber ?? '',
      role: role,
      profilePictureUrl: user.photoURL,
    );
    _logger.i('createProfileWithRole: profile created (role=$role)');
  }

  /// Let the signed-in user change their own role (client <-> shipper only).
  /// Admin roles cannot be self-assigned.
  Future<User?> changeMyRole(String newRole) async {
    if (newRole != 'client' && newRole != 'shipper') {
      throw AuthServiceException('Rôle non autorisé');
    }
    final userId = currentUserId;
    if (userId == null) throw Exception('Aucun utilisateur connecté');
    final updated = await updateUserRole(userId, newRole);
    _logger.i('changeMyRole: role updated to $newRole');
    return updated;
  }

  /// Get current user profile from the database.
  Future<User?> getCurrentUserProfile() async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final response = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return User.fromJson(response);
    } catch (e) {
      _logger.e('Error getting current user profile: $e');
      return null;
    }
  }

  /// Whether a profile row exists for the current Firebase user.
  ///
  /// Tri-state: `true` = a row exists, `false` = the row definitively does not
  /// exist, `null` = the lookup failed (transient/network) and the caller must
  /// not draw a conclusion. Used by the account gate to only offer the role
  /// picker to genuinely new users (never on a transient error).
  Future<bool?> hasProfile() async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;
      // Without an active access token the anon key is used and RLS filters
      // every row out — the query "succeeds" but is empty, which would look
      // like a definitive "no profile". Treat that as indeterminate so the
      // account gate keeps retrying instead of showing the role picker to a
      // returning user (web: session restore / popup can momentarily run with
      // no token).
      if (!SupabaseConfig.hasAccessToken) return null;
      final response = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      _logger.e('Error checking profile existence: $e');
      return null;
    }
  }

  /// Update user profile.
  Future<User?> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? profilePictureUrl,
    String? wechat,
    String? whatsapp,
    String? telegram,
    String? facebook,
    String? instagram,
    String? tiktok,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (profilePictureUrl != null) {
        updateData['profile_picture_url'] = profilePictureUrl;
      }
      if (wechat != null) updateData['wechat'] = wechat.isEmpty ? null : wechat;
      if (whatsapp != null) {
        updateData['whatsapp'] = whatsapp.isEmpty ? null : whatsapp;
      }
      if (telegram != null) {
        updateData['telegram'] = telegram.isEmpty ? null : telegram;
      }
      if (facebook != null) {
        updateData['facebook'] = facebook.isEmpty ? null : facebook;
      }
      if (instagram != null) {
        updateData['instagram'] = instagram.isEmpty ? null : instagram;
      }
      if (tiktok != null) updateData['tiktok'] = tiktok.isEmpty ? null : tiktok;

      final response = await SupabaseConfig.client
          .from('users')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      _logger.i('User profile updated');
      return User.fromJson(response);
    } catch (e) {
      _logger.e('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Get user by ID (Supabase UUID).
  Future<User?> getUserById(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return User.fromJson(response);
    } catch (e) {
      _logger.e('Error getting user: $e');
      return null;
    }
  }

  // ==========================================================================
  // ADMIN / SUPER_ADMIN METHODS (founder = full control)
  // ==========================================================================

  /// List all users (admin / super_admin). Excludes own row.
  Future<List<User>> getAllUsers({int limit = 200, int offset = 0}) async {
    try {
      final response = await SupabaseConfig.client
          .from('users')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final userId = currentUserId;
      return (response as List)
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .where((u) => u.id != userId)
          .toList();
    } catch (e) {
      _logger.e('Error getting all users: $e');
      return [];
    }
  }

  /// Update a user's role (admin / super_admin).
  Future<User?> updateUserRole(String userId, String newRole) async {
    try {
      final response = await SupabaseConfig.client
          .from('users')
          .update({
            'role': newRole,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();
      _logger.i('User role updated to $newRole');
      return User.fromJson(response);
    } catch (e) {
      _logger.e('Error updating user role: $e');
      rethrow;
    }
  }

  /// Activate or deactivate any user (admin / super_admin).
  Future<User?> setUserActive(String userId, bool active) async {
    try {
      final response = await SupabaseConfig.client
          .from('users')
          .update({
            'is_active': active,
            'deactivated_at': active ? null : DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();
      _logger.i('User active=$active');
      return User.fromJson(response);
    } catch (e) {
      _logger.e('Error setting user active: $e');
      rethrow;
    }
  }

  /// Permanently delete any user (super_admin only). Calls the delete-account
  /// edge function in admin mode.
  Future<void> deleteUserAsAdmin(String targetUserUuid) async {
    try {
      _logger.i('=== Super admin deletes user $targetUserUuid ===');
      final user = _auth.currentUser;
      if (user == null) throw Exception('Aucun utilisateur connecté');
      final adminToken = await user.getIdToken(true);
      final response = await http.post(
        Uri.parse(
          '${SupabaseConfig.supabaseUrl}/functions/v1/delete-account',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminToken': adminToken,
          'targetUserUuid': targetUserUuid,
        }),
      );
      _logger.i('admin delete-account: HTTP ${response.statusCode}');
      if (response.statusCode != 200) {
        throw Exception(
          'Échec de la suppression (${response.statusCode}): ${response.body}',
        );
      }
      _logger.i('User deleted by admin');
    } catch (e) {
      _logger.e('Error deleting user as admin: $e');
      rethrow;
    }
  }

  /// Factory reset (super_admin only). Calls the `admin-reset` edge function.
  ///
  /// [mode] is one of:
  ///   - 'tables'   : wipes all public tables + uploaded files (accounts kept)
  ///   - 'accounts' : deletes every auth account (Firebase + Supabase Auth)
  ///   - 'full'     : accounts first, then tables
  Future<Map<String, dynamic>> resetPlatformData(String mode) async {
    try {
      _logger.i('=== Super admin factory reset (mode=$mode) ===');
      final user = _auth.currentUser;
      if (user == null) throw Exception('Aucun utilisateur connecté');
      final adminToken = await user.getIdToken(true);
      final response = await http.post(
        Uri.parse('${SupabaseConfig.supabaseUrl}/functions/v1/admin-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'adminToken': adminToken, 'mode': mode}),
      );
      _logger.i('admin-reset: HTTP ${response.statusCode}');
      final body = response.body.isNotEmpty
          ? (jsonDecode(response.body) as Map<String, dynamic>)
          : <String, dynamic>{};
      if (response.statusCode != 200) {
        throw Exception(
          'Échec de la réinitialisation (${response.statusCode}): '
          '${body['error'] ?? response.body}',
        );
      }
      _logger.i('Factory reset completed: $body');
      return body;
    } catch (e) {
      _logger.e('Error resetting platform data: $e');
      rethrow;
    }
  }

  /// Platform-wide stats for the founder dashboard.
  Future<Map<String, dynamic>?> getPlatformStats() async {
    try {
      final users =
          await SupabaseConfig.client.from('users').select('id, role');
      final usersList = users as List;
      final clients = usersList.where((u) => u['role'] == 'client').length;
      final shippers = usersList.where((u) => u['role'] == 'shipper').length;
      final admins = usersList
          .where((u) => u['role'] == 'admin' || u['role'] == 'super_admin')
          .length;

      final shipments =
          await SupabaseConfig.client.from('shipments').select('id, status');
      final shipmentsList = shipments as List;
      final activeShipments =
          shipmentsList.where((s) => s['status'] == 'active').length;

      final bookings =
          await SupabaseConfig.client.from('bookings').select('id, status');
      final bookingsList = bookings as List;
      final activeBookings = bookingsList
          .where((b) => b['status'] == 'pending' || b['status'] == 'confirmed')
          .length;

      return {
        'total_users': usersList.length,
        'clients': clients,
        'shippers': shippers,
        'admins': admins,
        'total_shipments': shipmentsList.length,
        'active_shipments': activeShipments,
        'total_bookings': bookingsList.length,
        'active_bookings': activeBookings,
      };
    } catch (e) {
      _logger.e('Error getting platform stats: $e');
      return null;
    }
  }

  // ==========================================================================
  // ACCOUNT DELETION REQUESTS (demandes web — super_admin only)
  // ==========================================================================

  /// Pending account deletion requests submitted from the public web page.
  /// RLS restricts reads to admin/super_admin.
  Future<List<AccountDeletionRequest>> getPendingDeletionRequests() async {
    try {
      final response = await SupabaseConfig.client
          .from('account_deletion_requests')
          .select()
          .eq('status', 'pending')
          .order('requested_at', ascending: false);
      return (response as List)
          .map((item) =>
              AccountDeletionRequest.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting pending deletion requests: $e');
      return [];
    }
  }

  /// Count of pending deletion requests — powers the founder dashboard badge.
  Future<int> countPendingDeletionRequests() async {
    try {
      final response = await SupabaseConfig.client
          .from('account_deletion_requests')
          .select('id')
          .eq('status', 'pending');
      return (response as List).length;
    } catch (e) {
      _logger.e('Error counting pending deletion requests: $e');
      return 0;
    }
  }

  /// History of deleted accounts (super_admin only). RLS restricts reads to
  /// the super_admin role.
  Future<List<DeletedAccount>> getDeletedAccounts() async {
    try {
      final response = await SupabaseConfig.client
          .from('deleted_accounts')
          .select()
          .order('deleted_at', ascending: false)
          .limit(200);
      return (response as List)
          .map((item) => DeletedAccount.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting deleted accounts: $e');
      return [];
    }
  }

  /// Approve a pending account deletion request (super_admin only). Calls the
  /// `delete-account` edge function in approval mode: archives the account
  /// into `deleted_accounts` (creation date + history), performs the full
  /// purge (public rows, storage, Supabase Auth + Firebase Auth), emails the
  /// user (Resend) and marks the request 'approved'.
  Future<Map<String, dynamic>> approveDeletionRequest(
    String requestId,
  ) async {
    try {
      _logger.i('=== Super admin approves deletion request $requestId ===');
      final user = _auth.currentUser;
      if (user == null) throw Exception('Aucun utilisateur connecté');
      final adminToken = await user.getIdToken(true);
      final response = await http.post(
        Uri.parse(
          '${SupabaseConfig.supabaseUrl}/functions/v1/delete-account',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminToken': adminToken,
          'requestId': requestId,
        }),
      );
      _logger.i('approve delete-account: HTTP ${response.statusCode}');
      final body = response.body.isNotEmpty
          ? (jsonDecode(response.body) as Map<String, dynamic>)
          : <String, dynamic>{};
      if (response.statusCode != 200) {
        throw Exception(
          'Échec de la suppression (${response.statusCode}): '
          '${body['error'] ?? response.body}',
        );
      }
      _logger.i('Deletion request approved: $body');
      return body;
    } catch (e) {
      _logger.e('Error approving deletion request: $e');
      rethrow;
    }
  }
}

/// A user-facing auth error with a friendly message.
class AuthServiceException implements Exception {
  final String message;

  AuthServiceException(this.message, {this.cause});

  final Object? cause;

  @override
  String toString() => message;
}
