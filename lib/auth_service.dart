import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fbauth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'supabase_config.dart';
import 'fcm_service.dart';

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

String supabaseUserIdFromFirebase(String firebaseUid) =>
    const Uuid().v5('$_uidNamePrefix$firebaseUid', _uidNamespace);

// ============================================================================
// APP AUTH STATE
// ============================================================================

class AppAuthState {
  final String? firebaseUid;
  final String? userId; // deterministic Supabase user id
  const AppAuthState({this.firebaseUid, this.userId});

  bool get isSignedIn => firebaseUid != null;
}

// ============================================================================
// AUTH SERVICE (FirebaseAuth + Supabase session)
// ============================================================================

class AuthService {
  AuthService({fbauth.FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? fbauth.FirebaseAuth.instance,
        _logger = Logger();

  final fbauth.FirebaseAuth _auth;
  final Logger _logger;

  fbauth.FirebaseAuth get firebaseAuth => _auth;

  /// Stream of authentication state. Yields the initial state immediately, then
  /// follows FirebaseAuth's `authStateChanges`. Every emitted signed-in user
  /// triggers an exchange of the Firebase ID token for a Supabase access token
  /// (minted by the `auth-exchange-firebase` Edge Function) BEFORE the signed-in
  /// state is emitted, so no downstream call can race ahead of the token swap.
  Stream<AppAuthState> get authStateChanges async* {
    final current = _auth.currentUser;
    if (current != null) {
      try {
        await _onAuthenticated(current);
      } catch (e) {
        _logger.e('Failed to restore Supabase session: $e');
      }
    }
    yield _buildState();

    await for (final user in _auth.authStateChanges()) {
      if (user != null) {
        try {
          await _onAuthenticated(user);
        } catch (e) {
          _logger.e('Failed to exchange Firebase token for Supabase: $e');
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
    return AppAuthState(firebaseUid: user.uid, userId: userId);
  }

  /// Exchange the current Firebase user's ID token for a Supabase access token
  /// (minted by the Edge Function) and point every Supabase call at it.
Future<void> _onAuthenticated(fbauth.User user) async {
    final token = await _exchangeForSupabaseToken(user);
    SupabaseConfig.setAccessToken(token);
    final userId = supabaseUserIdFromFirebase(user.uid);
    await FcmService.instance.registerToken(userId);
  }

  Future<String> _exchangeForSupabaseToken(fbauth.User user) async {
    final idToken = await user.getIdToken(true);
    final response = await http.post(
      Uri.parse(
        '${SupabaseConfig.supabaseUrl}/functions/v1/auth-exchange-firebase',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Ã‰chec de l\'Ã©change de session (${response.statusCode}): '
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
      _logger.i('Signing up user with email: $email');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('CrÃ©ation du compte impossible');
      }

      await user.updateDisplayName(fullName);
      await _onAuthenticated(user);

      await _createUserProfile(
        userId: supabaseUserIdFromFirebase(user.uid),
        email: email,
        fullName: fullName,
        phone: phone,
        role: role,
      );

      _logger.i('User created successfully: ${user.uid}');
    } on fbauth.FirebaseAuthException catch (e) {
      _logger.e('Sign up error: ${e.message}');
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
      _logger.i('Signing in user with email: $email');

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = _auth.currentUser;
      if (user == null) throw Exception('Connexion impossible');

      await _onAuthenticated(user);
      await _ensureProfileIfAbsent(user, email: email);

      _logger.i('User signed in successfully');
    } on fbauth.FirebaseAuthException catch (e) {
      _logger.e('Sign in error: ${e.message}');
      throw AuthServiceException(e.message ?? 'Erreur de connexion');
    } catch (e) {
      _logger.e('Unexpected error during sign in: $e');
      rethrow;
    }
  }

  /// Sign in with Google (Firebase).
  Future<void> signInWithGoogle() async {
    try {
      _logger.i('Signing in with Google');

final account = await GoogleSignIn.instance.authenticate();
      final tokens = account.authentication;
      final credential = fbauth.GoogleAuthProvider.credential(
        idToken: tokens.idToken,
      );

      await _auth.signInWithCredential(credential);
      final user = _auth.currentUser;
      if (user == null) throw Exception('Connexion Google impossible');

      await _onAuthenticated(user);
      await _ensureProfileIfAbsent(user, email: user.email);

      _logger.i('Google sign in succeeded');
    } on GoogleSignInException catch (e) {
      _logger.e('Google sign in failed: $e');
      final message = switch (e.code) {
        GoogleSignInExceptionCode.canceled => 'Connexion Google annulée',
        GoogleSignInExceptionCode.clientConfigurationError =>
          'Configuration Google sign-in incorrecte',
        GoogleSignInExceptionCode.providerConfigurationError =>
          'Le fournisseur Google n\'est pas configuré',
        GoogleSignInExceptionCode.uiUnavailable =>
          'Interface de connexion indisponible',
        GoogleSignInExceptionCode.interrupted =>
          'Connexion Google interrompue',
        GoogleSignInExceptionCode.userMismatch =>
          'Utilisateur Google incohérent',
        GoogleSignInExceptionCode.unknownError =>
          'Erreur Google inconnue',
      };
      final detail = e.description;
      throw AuthServiceException(
        detail == null || detail.isEmpty
            ? message
            : '$message ($detail)',
        cause: e,
      );
    } catch (e) {
      _logger.e('Unexpected error during Google sign in: $e');
      rethrow;
    }
  }

  /// Sign out the current user (Firebase + reset Supabase to anon).
Future<void> signOut() async {
    try {
      _logger.i('Signing out user');
      await FcmService.instance.clearToken();
      await GoogleSignIn.instance.signOut();
      await _auth.signOut();
      SupabaseConfig.reset();
      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Sign out error: $e');
      rethrow;
    }
  }

  /// Request a password reset email.
  Future<void> resetPassword(String email) async {
    try {
      _logger.i('Requesting password reset for: $email');
      await _auth.sendPasswordResetEmail(email: email);
      _logger.i('Password reset email sent');
    } on fbauth.FirebaseAuthException catch (e) {
      _logger.e('Reset password error: ${e.message}');
      throw AuthServiceException(e.message ?? 'Erreur de rÃ©initialisation');
    } catch (e) {
      _logger.e('Unexpected error during password reset: $e');
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

  /// Create (idempotent) the user profile in the database. RLS allows the
  /// insert only when `auth.uid() = id`, which holds because the Supabase token
  /// minted for this Firebase user has `sub == id`.
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      await SupabaseConfig.client.from('users').insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'role': role,
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
  /// minimal one so the user can be routed by role.
  Future<void> _ensureProfileIfAbsent(fbauth.User user, {String? email}) async {
    final existing = await getCurrentUserProfile();
    if (existing != null) return;

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
      );
    } catch (e) {
      _logger.w('Could not auto-create profile: $e');
    }
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

  /// Update user profile.
  Future<User?> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? profilePictureUrl,
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
}

/// A user-facing auth error with a friendly message.
class AuthServiceException implements Exception {
  final String message;
  AuthServiceException(this.message, {this.cause});

  final Object? cause;

  @override
  String toString() => message;
}
