import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/index.dart';
import '../utils/error_dialog.dart';

/// App bar logout button shown in every role's header (client, shipper, admin
/// and super_admin / founder). Confirms before signing out, then clears the
/// account-scoped providers so a re-auth cannot surface the previous user's
/// data.
class LogoutIconButton extends ConsumerWidget {
  const LogoutIconButton({super.key, this.color = Colors.white});

  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Se déconnecter',
      icon: Icon(Icons.logout_rounded, color: color),
      onPressed: () => _confirmSignOut(context, ref),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(authServiceProvider).signOut();
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentShipperProvider);
    } catch (e) {
      if (context.mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }
}
