import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../core/config/supabase_config.dart';
import '../models/models.dart';
import './fcm_service.dart';

// ============================================================================
// APP AUTH STATE
// ============================================================================

class AppAuthState {
  final String? userId; // Supabase user id (uuid)
  final String? email;
  final bool emailVerified;

  const AppAuthState({
    this.userId,
    this.email,
    this.emailVerified = false,
  });

  bool get isSignedIn => userId != null;
}

/// Result of a Google sign-in. `isNewUser` is true when the Google account has
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
// AUTH SERVICE (Supabase Auth natif)
// ============================================================================

/// Authentification basée sur Supabase Auth natif.
///
/// Contrairement à l'ancien pont Firebase -> Supabase :
///  - la session est gérée par `supabase_flutter` (persistée, PKCE, deep link
///    `com.cargolink.dz.cargolink://login-callback` reconnu automatiquement) ;
///  - le jeton d'accès est attaché à chaque requête par le SDK, donc la RLS
///    sur `auth.uid()` fonctionne sans callback `accessToken` ;
///  - `users.id` == `auth.uid()` : le profil est protégé par la RLS.
class AuthService {
  AuthService() : _logger = Logger();

  final Logger _logger;

  // ==========================================================================
  // SESSION
  // ==========================================================================

  Session? get currentSession => Supabase.instance.client.auth.currentSession;

  /// Id Supabase (uuid) de l'utilisateur actuellement connecté.
  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  bool get isAuthenticated => currentUserId != null;

  /// Email vérifié (confirmation d'inscription). Sans session authentifiée,
  /// renvoie `false`.
  bool get emailVerified =>
      Supabase.instance.client.auth.currentUser?.emailConfirmedAt != null;

  /// Id du dernier utilisateur pour lequel un token FCM a été enregistré, pour
  /// ne pas re-registrer à chaque rafraîchissement de session.
  String? _fcmRegisteredUserId;

  /// Stream de l'état d'authentification. Émet immédiatement l'état initial
  /// (session restaurée par `Supabase.initialize`), puis suit les événements
  /// Supabase (`initialSession`, `signedIn`, `signedOut`, `tokenRefreshed`,
  /// `userUpdated`…).
  Stream<AppAuthState> get authStateChanges async* {
    yield _buildState(currentSession);

    await for (final authState
        in Supabase.instance.client.auth.onAuthStateChange) {
      final session = authState.session;
      final userId = session?.user.id;
      if (userId != null && userId != _fcmRegisteredUserId) {
        try {
          await FcmService.instance.registerToken(userId);
          _fcmRegisteredUserId = userId;
        } catch (e) {
          _logger.w('FCM token registration failed (ignored): $e');
        }
      }
      yield _buildState(session);
    }
  }

  AppAuthState _buildState(Session? session) {
    final user = session?.user;
    if (user == null) return const AppAuthState();
    return AppAuthState(
      userId: user.id,
      email: user.email,
      emailVerified: user.emailConfirmedAt != null,
    );
  }

  // ==========================================================================
  // AUTHENTICATION METHODS
  // ==========================================================================

  /// Sign up with email and password (Supabase Auth).
  ///
  /// La confirmation d'email est activée côté serveur : `signUp` ne renvoie
  /// pas de session. Le rôle, le nom complet et le téléphone sont stockés dans
  /// les `user_metadata` ; le profil `users` est créé à la première session
  /// authentifiée via [_ensureProfileIfAbsent].
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role, // client or shipper
  }) async {
    try {
      _logger.i('=== Email sign-up === email=$email role=$role');
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: SupabaseConfig.authRedirectUrl,
        data: {'full_name': fullName, 'phone': phone, 'role': role},
      );
      // Seulement si la confirmation d'email est désactivée (session donnée
      // immédiatement), le profil est créé tout de suite.
      if (response.session != null) {
        await _ensureProfileIfAbsent();
      }
      _logger.i('signUp: SUCCESS');
    } on AuthException catch (e) {
      _logger.e('Sign up error: ${e.message} (code ${e.code})');
      throw AuthServiceException(_authErrorMessage(e));
    } catch (e) {
      _logger.e('Unexpected error during sign up: $e');
      rethrow;
    }
  }

  /// Sign in with email and password (Supabase Auth).
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('=== Email sign-in === email=$email');
      await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);
      _logger.i('signInWithEmail: Supabase auth OK');
      await _ensureProfileIfAbsent();
      _logger.i('signInWithEmail: SUCCESS');
    } on AuthException catch (e) {
      _logger.e('Email sign-in error: ${e.message} (code ${e.code})');
      throw AuthServiceException(_authErrorMessage(e));
    } catch (e) {
      _logger.e('Unexpected error during email sign in: $e');
      rethrow;
    }
  }

  /// Sign in with Google.
  ///
  /// Disponible uniquement sur mobile (Android / iOS / macOS) : on utilise
  /// `google_sign_in` pour obtenir un `idToken`, échangé contre une session
  /// Supabase via `signInWithIdToken` (ce qui crée/mappe automatiquement
  /// l'utilisateur GoTrue). Sur web et desktop, un message clair est affiché
  /// (pas de client Google Identity Services configuré dans `web/index.html`).
  ///
  /// Renvoie [GoogleSignInResult]. Quand `isNewUser` est vrai, aucune ligne
  /// `users` n'existe : l'écran role picker doit être affiché.
  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      _logger.i('=== Google sign-in ===');
      _logger.i('Platform: ${kIsWeb ? 'web' : defaultTargetPlatform.name}');

      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux) {
        _logger.e(
          'Google sign-in unsupported on '
          '${kIsWeb ? 'web' : defaultTargetPlatform.name}',
        );
        throw AuthServiceException(
          'Google Sign-In n\'est pas encore disponible sur cette plateforme. '
          'Utilisez email/mot de passe ou l\'application mobile.',
        );
      }

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _logger.w('Google sign-in: user cancelled the dialog');
        throw AuthServiceException('Connexion Google annulée');
      }
      _logger.i('Google sign-in: account email=${googleUser.email}');
      final googleAuth = await googleUser.authentication;
      _logger.i(
        'Google sign-in: idToken=${googleAuth.idToken != null} '
        'accessToken=${googleAuth.accessToken != null}',
      );
      if (googleAuth.idToken == null) {
        throw AuthServiceException('Connexion Google impossible');
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      final user = Supabase.instance.client.auth.currentUser;
      _logger.i('Google sign-in: Supabase user id=${user?.id}');

      // First-time detection: no profile row means the user must pick a role.
      final existing = await getCurrentUserProfile();
      final isNewUser = existing == null;
      if (isNewUser) {
        _logger.i('Google sign-in: NEW user, role must be chosen');
        final meta = _googleMetadata(user?.userMetadata, user?.identities);
        return GoogleSignInResult(
          isNewUser: true,
          email: user?.email,
          fullName: meta['full_name'] as String?,
          photoUrl: meta['avatar_url'] as String?,
        );
      }
      _logger.i('Google sign-in: returning user (role=${existing.role})');

      // Existing user: attach the Google profile picture and display name when
      // missing locally, so the avatar/name stay in sync with Google.
      final meta = _googleMetadata(user?.userMetadata, user?.identities);
      final googlePhoto = meta['avatar_url'] as String?;
      final googleName = meta['full_name'] as String?;
      if ((googlePhoto != null && googlePhoto.isNotEmpty) ||
          (googleName != null && googleName.isNotEmpty)) {
        try {
          final updateData = <String, dynamic>{
            'updated_at': DateTime.now().toIso8601String(),
          };
          final needsPhoto = (existing.profilePictureUrl == null ||
                  existing.profilePictureUrl!.isEmpty) &&
              googlePhoto != null &&
              googlePhoto.isNotEmpty;
          final needsName = existing.fullName.isEmpty &&
              googleName != null &&
              googleName.isNotEmpty;
          if (needsPhoto) updateData['profile_picture_url'] = googlePhoto;
          if (needsName) updateData['full_name'] = googleName;
          if (needsPhoto || needsName) {
            await SupabaseConfig.client
                .from('users')
                .update(updateData)
                .eq('id', existing.id);
            _logger.i(
              'Google sign-in: profile synced '
              '(photo=${needsPhoto ? 'yes' : 'no'}, '
              'name=${needsName ? 'yes' : 'no'})',
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

  /// Extraits (nom, avatar) du profil Google depuis les métadonnées du user
  /// Supabase (avec repli sur les données d'identité OAuth).
  Map<String, dynamic> _googleMetadata(
    Map<String, dynamic>? userMetadata,
    List<UserIdentity>? identities,
  ) {
    final meta = userMetadata ?? const <String, dynamic>{};
    UserIdentity? googleIdentity;
    for (final identity in identities ?? const <UserIdentity>[]) {
      if (identity.provider == 'google') {
        googleIdentity = identity;
        break;
      }
    }
    final idData = googleIdentity?.identityData ?? const <String, dynamic>{};
    String firstString(List<Object?> keys) {
      for (final key in keys) {
        final value = meta[key] ?? idData[key];
        if (value is String && value.isNotEmpty) return value;
      }
      return '';
    }

    return {
      'full_name': firstString(['full_name', 'name']),
      'avatar_url': firstString(['avatar_url', 'picture']),
    };
  }

  /// Sign out (Supabase Auth local). Le token FCM est nettoyé et le flux
  /// Google est déconnecté (mobile uniquement, ne bloque jamais le sign-out).
  Future<void> signOut() async {
    try {
      _logger.i('=== Sign out ===');
      try {
        await FcmService.instance.clearToken();
        _logger.i('signOut: FCM token cleared');
      } catch (e) {
        _logger.w('signOut: FCM token clear failed (ignored): $e');
      }
      _fcmRegisteredUserId = null;
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
      await Supabase.instance.client.auth.signOut();
      _logger.i('signOut: Supabase session closed, SUCCESS');
    } catch (e) {
      _logger.e('Sign out error: $e');
      rethrow;
    }
  }

  /// Request a password reset email (lien PKCE renvoyé vers [authRedirectUrl]).
  Future<void> resetPassword(String email) async {
    try {
      _logger.i('=== Password reset === email=$email');
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: SupabaseConfig.authRedirectUrl,
      );
      _logger.i('Password reset email sent');
    } on AuthException catch (e) {
      _logger.e('Reset password error: ${e.message} (code ${e.code})');
      throw AuthServiceException(_authErrorMessage(e));
    } catch (e) {
      _logger.e('Unexpected error during password reset: $e');
      rethrow;
    }
  }

  /// Change the password of the signed-in user.
  ///
  /// Le mot de passe actuel est d'abord vérifié (connexion locale), puis le
  /// changement est appliqué. Une session volée ne peut pas changer le mot de
  /// passe silencieusement.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw AuthServiceException('Session expirée, reconnectez-vous');
      }
      final email = user.email;
      if (email == null || email.isEmpty) {
        throw AuthServiceException(
            'Impossible de changer le mot de passe : aucun email associé');
      }

      await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: currentPassword);
      _logger.i('changePassword: current password verified');

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      _logger.i('changePassword: password updated');
    } on AuthException catch (e) {
      _logger.e('Change password error: ${e.code} ${e.message}');
      throw AuthServiceException(_passwordErrorToMessage(e.code, e.message));
    } catch (e) {
      _logger.e('Unexpected error during password change: $e');
      rethrow;
    }
  }

  String _passwordErrorToMessage(String? code, String? message) {
    switch (code) {
      case 'weak_password':
        return 'Le mot de passe est trop faible (6 caractères minimum).';
      case 'invalid_credentials':
      case 'invalid_grant':
        return 'Le mot de passe actuel est incorrect.';
      case 'same_password':
        return 'Le nouveau mot de passe doit être différent de l\'actuel.';
      case 'over_request_rate_limit':
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      case 'reauthentication_needed':
        return 'Veuillez vous reconnecter avant de changer votre mot de passe.';
      default:
        return message ?? 'Erreur lors du changement de mot de passe';
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
  /// elapsed). Calls the `delete_my_account` RPC (SECURITY DEFINER) which
  /// purges every row (public tables, storage objects) and the Supabase auth
  /// user, server-side.
  Future<void> deleteAccountPermanently() async {
    try {
      _logger.i('=== Permanent account deletion ===');
      await Supabase.instance.client.rpc('delete_my_account');
      _logger.i('delete_my_account: OK');
      await signOut();
      _logger.i('Account permanently deleted');
    } catch (e) {
      _logger.e('Error deleting account permanently: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // USER PROFILE METHODS
  // ==========================================================================

  /// Create (idempotent) the user profile in the database. RLS allows the
  /// insert only when `auth.uid() = id`, which holds with the native session.
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

  /// If a profile row does not exist yet, create it from the `user_metadata`
  /// (role, full_name, phone) set at sign-up. Skipped for Google-only accounts
  /// (identity `google`) : ces utilisateurs passent par le role picker
  /// ([createProfileWithRole]) pour choisir leur rôle.
  Future<void> _ensureProfileIfAbsent() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _logger.i('_ensureProfileIfAbsent: checking users row');
    final existing = await getCurrentUserProfile();
    if (existing != null) {
      _logger
          .i('_ensureProfileIfAbsent: profile exists (role=${existing.role})');
      return;
    }

    var isGoogleOnly = false;
    for (final identity in user.identities ?? const <UserIdentity>[]) {
      if (identity.provider == 'google') {
        isGoogleOnly = true;
        break;
      }
    }
    if (isGoogleOnly) {
      _logger
          .i('_ensureProfileIfAbsent: Google account, role must be chosen');
      return;
    }

    final meta = user.userMetadata ?? const <String, dynamic>{};
    final role = _stringValue(meta, 'role') ?? 'client';
    final fullName = _stringValue(meta, 'full_name') ??
        ((user.email ?? '').isNotEmpty
            ? user.email!.split('@').first
            : 'Utilisateur');
    final phone = _stringValue(meta, 'phone') ?? '';
    try {
      await _createUserProfile(
        userId: user.id,
        email: user.email ?? 'user@cargolink.app',
        fullName: fullName,
        phone: phone,
        role: role,
        profilePictureUrl: _stringValue(meta, 'avatar_url') ??
            _stringValue(meta, 'picture'),
      );
      _logger.i('_ensureProfileIfAbsent: profile auto-created (role=$role)');
    } catch (e) {
      _logger.w('Could not auto-create profile: $e');
    }
  }

  String? _stringValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Create the CargoLink profile for a brand-new user (e.g. first Google
  /// sign-in) with the role they picked. Used by the role-selection flow.
  /// Les données Google (avatar, nom) sont reprises des métadonnées.
  Future<void> createProfileWithRole({
    required String role,
    String? fullName,
    String? phone,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('Aucun utilisateur connecté');
    }
    final meta = user.userMetadata ?? const <String, dynamic>{};
    final metaFullName = _stringValue(meta, 'full_name') ??
        _stringValue(meta, 'name');
    final metaPhone = _stringValue(meta, 'phone');
    final metaAvatar =
        _stringValue(meta, 'avatar_url') ?? _stringValue(meta, 'picture');
    await _createUserProfile(
      userId: user.id,
      email: user.email ?? 'user@cargolink.app',
      fullName: fullName ??
          metaFullName ??
          ((user.email ?? '').isNotEmpty
              ? user.email!.split('@').first
              : 'Utilisateur'),
      phone: phone ?? metaPhone ?? '',
      role: role,
      profilePictureUrl: metaAvatar,
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

  /// Whether a profile row exists for the current Supabase user.
  ///
  /// Tri-state: `true` = a row exists, `false` = the row definitively does not
  /// exist, `null` = the lookup failed (transient/network) and the caller must
  /// not draw a conclusion. Used by the account gate to only offer the role
  /// picker to genuinely new users (never on a transient error).
  Future<bool?> hasProfile() async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;
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
      if (tiktok != null) {
        updateData['tiktok'] = tiktok.isEmpty ? null : tiktok;
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

  /// RGPD export : rassemble les données personnelles de l'utilisateur courant
  /// (profil + tables liées) dans une structure JSON-encodable. Chaque section
  /// est collectée de façon isolée : une erreur sur une table ne casse pas le
  /// reste de l'export.
  Future<Map<String, dynamic>> generateDataExport() async {
    final userId = currentUserId;
    final stamp = DateTime.now().toIso8601String();
    final data = <String, dynamic>{
      'generated_at': stamp,
      'user_id': userId,
    };

    Future<List<dynamic>> trySelect(
      String table,
      String column,
      String value,
    ) async {
      try {
        final res = await SupabaseConfig.client
            .from(table)
            .select()
            .eq(column, value);
        return res;
      } catch (e) {
        _logger.e('Export: cannot read $table: $e');
        return [];
      }
    }

    // --- Profil public.
    if (userId != null) {
      try {
        final profile = await SupabaseConfig.client
            .from('users')
            .select()
            .eq('id', userId)
            .maybeSingle();
        data['profile'] = profile ?? <String, dynamic>{};
      } catch (e) {
        _logger.e('Export: cannot read profile: $e');
        data['profile'] = <String, dynamic>{};
      }
    }

    data['bookings'] =
        await trySelect('bookings', 'client_id', userId ?? '');
    data['delivery_subscriptions'] =
        await trySelect('delivery_subscriptions', 'user_id', userId ?? '');
    data['referral_codes'] =
        await trySelect('referral_codes', 'user_id', userId ?? '');
    data['referrals_parrain'] =
        await trySelect('referrals', 'parrain_id', userId ?? '');
    data['referrals_filleul'] =
        await trySelect('referrals', 'filleul_id', userId ?? '');
    data['referral_batches'] =
        await trySelect('referral_batches', 'parrain_id', userId ?? '');
    data['referral_earnings'] =
        await trySelect('referral_earnings', 'parrain_id', userId ?? '');
    data['payments'] =
        await trySelect('payments', 'user_id', userId ?? '');

    // Conversations où l'utilisateur est participant.
    if (userId != null) {
      try {
        final convos = await SupabaseConfig.client
            .from('conversations')
            .select()
            .or('user1_id.eq.$userId,user2_id.eq.$userId');
        data['conversations'] = convos;
      } catch (e) {
        _logger.e('Export: cannot read conversations: $e');
        data['conversations'] = [];
      }
    }

    return data;
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
  // EMAIL VERIFICATION
  // ==========================================================================

  /// Re-send the email verification link for the given email address (or the
  /// signed-in user's email). Fonctionne sans session (écran de vérification).
  Future<void> resendVerificationEmail({String? email}) async {
    try {
      _logger.i('=== Resend verification email ===');
      final emailAddress = email ??
          Supabase.instance.client.auth.currentUser?.email;
      if (emailAddress == null || emailAddress.isEmpty) {
        throw Exception('Aucun email associé');
      }
      await Supabase.instance.client.auth.resend(
        email: emailAddress,
        type: OtpType.signup,
        emailRedirectTo: SupabaseConfig.authRedirectUrl,
      );
      _logger.i('Verification email re-sent');
    } on AuthException catch (e) {
      _logger
          .e('Resend verification email error: ${e.message} (code ${e.code})');
      throw AuthServiceException(e.message);
    } catch (e) {
      _logger.e('Unexpected error while resending verification email: $e');
      rethrow;
    }
  }

  /// Whether the email is verified now (lecture locale de `emailConfirmedAt`,
  /// mise à jour après la confirmation du lien dans le flux PKCE).
  Future<bool> refreshEmailVerified() async {
    return Supabase.instance.client.auth.currentUser?.emailConfirmedAt != null;
  }

  // ==========================================================================
  // ADMIN / SUPER_ADMIN METHODS (founder = full control)
  // ==========================================================================

  /// Fetch users by a specific set of IDs (admin use — shipper-type drill-down).
  Future<List<User>> getUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final response = await SupabaseConfig.client
          .from('users')
          .select()
          .inFilter('id', ids)
          .order('created_at', ascending: false);

      final userId = currentUserId;
      return (response as List)
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .where((u) => u.id != userId)
          .toList();
    } catch (e) {
      _logger.e('Error getting users by IDs: $e');
      return [];
    }
  }

  /// Résout les ids des utilisateurs (expéditeurs) d'un type donné via la
  /// table `shippers`. Filtre effectué côté serveur (`inFilter`), préférable
  /// à un filtre embedded dont la sémantique semi-jointure s'est révélée non
  /// fiable (voir `_shipperIdsOfType` dans shipper_shipment_service.dart).
  Future<List<String>> getShipperUserIdsOfType(String shipperType) async {
    try {
      final rows = await SupabaseConfig.client
          .from('shippers')
          .select('user_id')
          .eq('shipper_type', shipperType);
      return (rows as List)
          .map((r) => r['user_id'] as String)
          .toSet()
          .toList();
    } catch (e) {
      _logger.e('Error getting shipper user ids of type: $e');
      return const [];
    }
  }

  /// List all users (admin / super_admin). Excludes own row.
  ///
  /// Optional server-side filters: [filterIds] restricts to the given user ids
  /// (shipper-type filter resolved beforehand), [role] restricts by role.
  /// Both are applied by PostgREST so pagination stays correct server-side.
  Future<List<User>> getAllUsers({
    int limit = 200,
    int offset = 0,
    List<String>? filterIds,
    String? role,
  }) async {
    try {
      var query = SupabaseConfig.client
          .from('users')
          .select();

      if (filterIds != null && filterIds.isNotEmpty) {
        query = query.inFilter('id', filterIds);
      } else if (filterIds != null) {
        return const [];
      }
      if (role != null) {
        query = query.eq('role', role);
      }

      final response = await query
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

  /// Permanently delete any user (super_admin only). Calls the
  /// `admin_delete_user` RPC (SECURITY DEFINER).
  Future<void> deleteUserAsAdmin(String targetUserUuid) async {
    try {
      _logger.i('=== Super admin deletes user $targetUserUuid ===');
      await Supabase.instance.client.rpc(
        'admin_delete_user',
        params: {'p_target_user_id': targetUserUuid},
      );
      _logger.i('User deleted by admin');
    } catch (e) {
      _logger.e('Error deleting user as admin: $e');
      rethrow;
    }
  }

  /// Factory reset (super_admin only). Calls the `admin_reset_platform` RPC
  /// (SECURITY DEFINER).
  ///
  /// [mode] is one of:
  ///   - 'tables'   : wipes all public tables + uploaded files (accounts kept)
  ///   - 'accounts' : deletes every auth account (Supabase Auth)
  ///   - 'full'     : accounts first, then tables
  Future<Map<String, dynamic>> resetPlatformData(String mode) async {
    try {
      _logger.i('=== Super admin factory reset (mode=$mode) ===');
      final result = await Supabase.instance.client.rpc(
        'admin_reset_platform',
        params: {'p_mode': mode},
      );
      _logger.i('Factory reset completed: $result');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return <String, dynamic>{'mode': mode};
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
  /// `admin_approve_deletion_request` RPC (SECURITY DEFINER) : archive dans
  /// `deleted_accounts`, purge complète (public, storage, auth), notification
  /// push à l'utilisateur et passage du statut à 'approved'.
  Future<Map<String, dynamic>> approveDeletionRequest(
    String requestId,
  ) async {
    try {
      _logger.i('=== Super admin approves deletion request $requestId ===');
      final result = await Supabase.instance.client.rpc(
        'admin_approve_deletion_request',
        params: {'p_request_id': requestId},
      );
      _logger.i('Deletion request approved: $result');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return <String, dynamic>{'request_id': requestId};
    } catch (e) {
      _logger.e('Error approving deletion request: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // MISC
  // ==========================================================================

  String _authErrorMessage(Object error) {
    if (error is AuthException) {
      switch (error.code) {
        case 'invalid_credentials':
          return 'Email ou mot de passe incorrect.';
        case 'email_not_confirmed':
          return 'Veuillez confirmer votre email avant de vous connecter.';
        case 'user_already_exists':
          return 'Un compte existe déjà avec cet email.';
        case 'weak_password':
          return 'Le mot de passe est trop faible (6 caractères minimum).';
        case 'same_password':
          return 'Le nouveau mot de passe doit être différent de l\'actuel.';
        case 'over_request_rate_limit':
          return 'Trop de tentatives. Réessayez dans quelques minutes.';
        case 'over_email_send_rate_limit':
          return 'L\'envoi d\'email est trop fréquent. Réessayez dans quelques minutes.';
        default:
          return error.message;
      }
    }
    return error.toString();
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