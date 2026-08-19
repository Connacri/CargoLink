import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';

/// Shown when a user logs in with a deactivated account (Facebook-style) or
/// with a pending deletion request within the 30-day grace period.
class AccountStatusScreen extends ConsumerStatefulWidget {
  final bool deletionPending;
  final DateTime? deletionRequestedAt;

  const AccountStatusScreen({
    super.key,
    this.deletionPending = false,
    this.deletionRequestedAt,
  });

  @override
  ConsumerState<AccountStatusScreen> createState() =>
      _AccountStatusScreenState();
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
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentShipperProvider);
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }

  String _remainingDays() {
    final requested = widget.deletionRequestedAt;
    if (requested == null) return '';
    final remaining = AuthServiceConstants.deletionGracePeriod -
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
        top: false,
        child: CustomScrollView(
          slivers: [
            GradientSliverHeader(
              title: deletion ? 'Suppression programmée' : 'Compte désactivé',
              subtitle: deletion
                  ? 'Votre compte sera bientôt supprimé'
                  : 'Votre compte est temporairement inactif',
              icon: deletion
                  ? Icons.delete_forever_outlined
                  : Icons.pause_circle_outline,
              gradient:
                  deletion ? AppTheme.errorGradient : AppTheme.warningGradient,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              sliver: SliverToBoxAdapter(
                child: StaggeredEntrance(
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppTheme.spaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedIconDot(
                          icon: deletion
                              ? Icons.delete_forever_outlined
                              : Icons.pause_circle_outline,
                          color: deletion
                              ? AppTheme.errorColor
                              : AppTheme.warningColor,
                          size: 28,
                        ),
                        const SizedBox(height: AppTheme.spaceMd),
                        Text(
                          deletion
                              ? 'Votre compte sera définitivement supprimé dans '
                                  '${_remainingDays()}. Connectez-vous à tout '
                                  'moment pour annuler la suppression.'
                              : 'Vous avez désactivé votre compte. Il est masqué '
                                  'et inaccessible, mais rien n\'est supprimé. '
                                  'Réactivez-le à tout moment pour retrouver '
                                  'votre profil, vos commandes et vos données.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceLg),
                        FilledButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  deletion ? _cancelDeletion() : _reactivate();
                                },
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
                        const SizedBox(height: AppTheme.spaceSm),
                        TextButton(
                          onPressed: _signOut,
                          child: const Text('Se déconnecter'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spaceLg)),
          ],
        ),
      ),
    );
  }
}

/// Constants used across account management screens.
class AuthServiceConstants {
  static const Duration deletionGracePeriod = Duration(days: 30);
}
