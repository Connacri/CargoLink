import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../supabase_config.dart';
import '../error_dialog.dart';

/// Shown right after an email/password sign-up (or when a signed-in user's
/// email is not verified yet). It tells the user to click the link in the
/// confirmation email, lets them re-send it, and only lets them into the app
/// once the email is verified.
///
/// The screen watches for the verification as soon as it happens:
///  - a periodic poll calls `refreshEmailVerified()` (which reloads the
///    Firebase user and triggers a fresh `idTokenChanges` emission);
///  - the app lifecycle is observed so that coming back from the mail app
///    (mobile) triggers an immediate re-check.
///
/// As soon as the email is verified, `authStateProvider` re-emits with
/// `emailVerified: true`, so [CargoLinkApp] automatically swaps this screen
/// for the app entry point — no manual button press needed.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with WidgetsBindingObserver {
  bool _sending = false;
  bool _checking = false;
  Timer? _pollTimer;
  bool _welcomed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _autoCheckVerified();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _autoCheckVerified();
    }
  }

  /// Reload the Firebase user and, if the email is now verified, refresh the
  /// auth state so the app entry point replaces this screen automatically.
  Future<bool> _autoCheckVerified() async {
    if (_checking) return false;
    if (mounted) setState(() => _checking = true);
    try {
      final verified =
          await ref.read(authServiceProvider).refreshEmailVerified();
      if (mounted && verified) {
        _onVerified();
      }
      return verified;
    } catch (_) {
      // Silent: the manual button still surfaces errors to the user.
      return false;
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _onVerified() {
    if (_welcomed) return;
    _welcomed = true;
    // Force both providers to re-emit with the freshly verified state; the
    // router in CargoLinkApp then swaps this screen for the app entry point.
    ref.invalidate(authStateProvider);
    ref.invalidate(currentUserProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email confirmé. Bienvenue sur CargoLink !'),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    try {
      await ref.read(authServiceProvider).resendVerificationEmail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de confirmation renvoyé. Vérifiez votre boîte.'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _checkVerified() async {
    try {
      final verified = await _autoCheckVerified();
      if (mounted && !verified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email pas encore confirmé. Cliquez sur le lien envoyé par mail.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(
                  radius: 48,
                  backgroundColor: AppTheme.warningColor,
                  child: Icon(Icons.mark_email_read, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Confirmez votre email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Un email de confirmation vous a été envoyé. '
                  'Cliquez sur le lien qu\'il contient pour activer votre compte, '
                  'puis revenez ici.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _checking ? null : _checkVerified,
                  child: _checking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('J\'ai confirmé mon email'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _sending ? null : _resend,
                  icon: const Icon(Icons.send),
                  label: Text(
                    _sending
                        ? 'Envoi en cours...'
                        : 'Renvoyer l\'email de confirmation',
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _signOut,
                  child: const Text('Se déconnecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
