import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'models.dart';
import 'supabase_config.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final _logger = Logger();

  // Stream for auth state changes
  // Seeds with the current session so the UI never blocks on "loading" at startup
  // (onAuthStateChange alone does not emit the initial state on desktop/web).
  Stream<AuthState> get authStateChanges async* {
    final session = _supabase.auth.currentSession;
    yield AuthState(
      session != null ? AuthChangeEvent.signedIn : AuthChangeEvent.signedOut,
      session,
    );
    yield* _supabase.auth.onAuthStateChange;
  }

  // Get current user session
  Session? get currentSession => _supabase.auth.currentSession;

  // Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Get current user auth object
  dynamic get currentAuthUser => _supabase.auth.currentUser;

  // ============================================================================
  // AUTHENTICATION METHODS
  // ============================================================================

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role, // client or shipper
  }) async {
    try {
      _logger.i('Signing up user with email: $email');

      // Create auth user
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role,
        },
      );

      if (authResponse.user != null) {
        // Create user profile in database
        await _createUserProfile(
          userId: authResponse.user!.id,
          email: email,
          fullName: fullName,
          phone: phone,
          role: role,
        );

        _logger.i('User created successfully: ${authResponse.user!.id}');
      }

      return authResponse;
    } on AuthException catch (e) {
      _logger.e('Sign up error: ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error during sign up: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Signing in user with email: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _logger.i('User signed in successfully');
      return response;
    } on AuthException catch (e) {
      _logger.e('Sign in error: ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error during sign in: $e');
      rethrow;
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      _logger.i('Signing in with Google');

      final oauthResponse = await _supabase.auth.getOAuthSignInUrl(
        provider: Provider.google,
        redirectTo: 'io.supabase.cargolink://login-callback',
      );

      final url = oauthResponse.url;
      if (url == null) {
        throw Exception('URL de connexion Google indisponible');
      }

      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Impossible d\'ouvrir le navigateur');
      }

      _logger.i('Google sign in URL launched successfully');
    } on AuthException catch (e) {
      _logger.e('Google sign in error: ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error during Google sign in: $e');
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      _logger.i('Signing out user');
      await _supabase.auth.signOut();
      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Sign out error: $e');
      rethrow;
    }
  }

  /// Request password reset
  Future<void> resetPassword(String email) async {
    try {
      _logger.i('Requesting password reset for: $email');

      await _supabase.auth.resetPasswordForEmail(email);

      _logger.i('Password reset email sent');
    } on AuthException catch (e) {
      _logger.e('Reset password error: ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error during password reset: $e');
      rethrow;
    }
  }

  /// Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      _logger.i('Updating password');

      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      _logger.i('Password updated successfully');
      return response;
    } on AuthException catch (e) {
      _logger.e('Update password error: ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error during password update: $e');
      rethrow;
    }
  }

  // ============================================================================
  // USER PROFILE METHODS
  // ============================================================================

  /// Create user profile in database
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      await _supabase.from('users').insert({
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

  /// Get current user profile
  Future<User?> getCurrentUserProfile() async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final response = await _supabase
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

  /// Update user profile
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

      final response = await _supabase
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

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final response = await _supabase
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

  /// Update user email
  Future<void> updateEmail(String newEmail) async {
    try {
      _logger.i('Updating email to: $newEmail');

      await _supabase.auth.updateUser(
        UserAttributes(email: newEmail),
      );

      // Update email in users table
      await _supabase
          .from('users')
          .update({'email': newEmail})
          .eq('id', currentUserId);

      _logger.i('Email updated successfully');
    } on AuthException catch (e) {
      _logger.e('Update email error: ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error during email update: $e');
      rethrow;
    }
  }

  /// Verify email
  Future<void> verifyEmail() async {
    try {
      _logger.i('Verifying email');

      final user = currentAuthUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      if (user.emailConfirmedAt != null) {
        _logger.i('Email already verified');
        return;
      }

      final email = user.email;
      if (email == null) {
        throw Exception('Email indisponible');
      }

      // Resend verification email
      await _supabase.auth.resend(
        email: email,
        type: OtpType.signup,
      );

      _logger.i('Verification email sent');
    } catch (e) {
      _logger.e('Error verifying email: $e');
      rethrow;
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => currentAuthUser != null;

  /// Check if email is verified
  bool get isEmailVerified =>
      currentAuthUser?.emailConfirmedAt != null;
}
