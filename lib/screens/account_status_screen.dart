import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../supabase_config.dart';
import '../error_dialog.dart';

/// Shown when a user logs in with a deactivated account (Facebook-style) or
/// with a pending deletion request within the 30-day grace period.
class AccountStatusScreen extends ConsumerStatefulWidget {
  final bool deletionPending;
  final DateTime? deletionRequestedAt;

  const AccountStatusScreen({
    Key? key,
    this.deletionPending = false,
    this.deletionRequestedAt,
  }) : super(key: key);

  @override
  ConsumerState<AccountStatusScreen> createState() => _AccountStatusScreenState();
}

class _AccountStatusScreenState extends ConsumerState<AccountStatusScreen> {
  bool _loading = false;

  Future<void> _reactivate() async {
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).reactivateAccount();
      ref.invalidate(currentUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte réactivé. Bienvenue sur CargoLink !'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelDeletion() async {
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).cancelAccountDeletion();
      ref.invalidate(currentUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suppression annulée. Compte réactivé.'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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

  String _remainingDays() {
    final requested = widget.deletionRequestedAt;
    if (requested == null) return '';
    final remaining =
        AuthServiceConstants.deletionGracePeriod -
            DateTime.now().difference(requested);
    final days = remaining.inDays + 1;
    return '${days.clamp(0, 999)} jour${days > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final deletion = widget.deletionPending;
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
                CircleAvatar(
                  radius: 48,
                  backgroundColor: deletion
                      ? AppTheme.errorColor
                      : AppTheme.warningColor,
                  child: Icon(
                    deletion
                        ? Icons.delete_forever_outlined
                        : Icons.pause_circle_outline,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  deletion ? 'Suppression programmée' : 'Compte désactivé',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  deletion
                      ? 'Votre compte sera définitivement supprimé dans '
                          '${_remainingDays()}. Connectez-vous à tout moment '
                          'pour annuler la suppression.'
                      : 'Vous avez désactivé votre compte. Il est masqué et '
                          'inaccessible, mais rien n\'est supprimé. '
                          'Réactivez-le à tout moment pour retrouver votre '
                          'profil, vos commandes et vos données.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : deletion ? _cancelDeletion : _reactivate,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          deletion
                              ? 'Annuler la suppression'
                              : 'Réactiver mon compte',
                        ),
                ),
                const SizedBox(height: 12),
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

/// Constants used across account management screens.
class AuthServiceConstants {
  static const Duration deletionGracePeriod = Duration(days: 30);
}
