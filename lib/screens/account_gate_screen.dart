import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../auth_service.dart';
import '../error_dialog.dart';
import '../main.dart';
import 'account_status_screen.dart';
import 'role_selection_screen.dart';

/// Checks the authenticated user's account status before entering the app:
///  - active account          -> HomeTabsScreen
///  - deactivated (Facebook)  -> reactivation screen
///  - deletion pending within grace period -> cancel-deletion screen
///  - deletion grace elapsed  -> purge account permanently, then sign out
class AccountGateScreen extends ConsumerWidget {
  const AccountGateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return user.when(
      data: (userData) {
        if (userData == null) {
          // Signed in (authState says so) but no profile row yet: this is a
          // brand-new user (e.g. first Google sign-in) who must pick a role.
          return const RoleSelectionScreen(firstTime: true);
        }

        // Pending permanent deletion.
        final deletionRequested = userData.deletionRequestedAt;
        if (deletionRequested != null) {
          final authService = ref.read(authServiceProvider);
          if (authService.deletionGraceElapsed(deletionRequested)) {
            // 30 days elapsed: purge now, then sign out.
            return _PurgeAndSignOut(authService: authService);
          }
          return AccountStatusScreen(
            deletionPending: true,
            deletionRequestedAt: deletionRequested,
          );
        }

        // Deactivated account (Facebook-style).
        if (!userData.isActive) {
          return const AccountStatusScreen(deletionPending: false);
        }

        return const HomeTabsScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Center(child: Text('Erreur: $e')),
    );
  }
}

/// Triggers the permanent deletion once the 30-day grace period has elapsed.
class _PurgeAndSignOut extends ConsumerStatefulWidget {
  final AuthService authService;
  const _PurgeAndSignOut({required this.authService});

  @override
  ConsumerState<_PurgeAndSignOut> createState() => _PurgeAndSignOutState();
}

class _PurgeAndSignOutState extends ConsumerState<_PurgeAndSignOut> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _purge();
  }

  Future<void> _purge() async {
    if (_started) return;
    _started = true;
    try {
      await widget.authService.deleteAccountPermanently();
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
