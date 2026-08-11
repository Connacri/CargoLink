import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/index.dart';
import '../../data/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';
import '../../app/home_tabs_screen.dart';
import './account_status_screen.dart';
import './role_selection_screen.dart';

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
          // Signed in (authState says so) but the profile provider returned
          // null. This can be a brand-new user (e.g. first Google sign-in) who
          // must pick a role, OR a transient profile-fetch failure. Re-verify
          // so a returning user who already has a role never lands on the role
          // picker again.
          return _GateRoleDecider(authService: ref.read(authServiceProvider));
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
      loading: () => const _GateLoading(),
      error: (e, s) => _GateError(message: 'Erreur: $e'),
    );
  }
}

/// Re-checks whether a profile really exists before showing the role picker.
class _GateRoleDecider extends ConsumerStatefulWidget {
  final AuthService authService;
  const _GateRoleDecider({required this.authService});

  @override
  ConsumerState<_GateRoleDecider> createState() => _GateRoleDeciderState();
}

class _GateRoleDeciderState extends ConsumerState<_GateRoleDecider> {
  bool _checked = false;
  bool _showRolePicker = false;
  int _retries = 0;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    // Tri-state: true = profile exists, false = definitively no row,
    // null = transient failure. Only a definitive "no row" may open the role
    // picker — a returning user who already picked a role must never see it
    // again (even for a single frame while the provider refreshes).
    final hasProfile = await widget.authService.hasProfile();
    if (!mounted) return;
    if (hasProfile == true) {
      // A profile exists but the provider returned null transiently. Invalidate
      // so the parent gate re-routes straight to home — never the role picker.
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentShipperProvider);
      return;
    }
    if (hasProfile == false) {
      setState(() {
        _checked = true;
        _showRolePicker = true;
      });
      return;
    }
    // Indeterminate: stay on the gate and retry instead of guessing.
    if (_retries < 3) {
      _retries++;
      Future.delayed(const Duration(milliseconds: 500), _verify);
      return;
    }
    setState(() => _checked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || !_showRolePicker) return const _GateLoading();
    return const RoleSelectionScreen(firstTime: true);
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
    return const _GateLoading();
  }
}

/// Full-screen gradient wrapper for the transient gate states.
class _GateScaffold extends StatelessWidget {
  const _GateScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(child: child),
      ),
    );
  }
}

/// Premium loading state used while the account status resolves.
class _GateLoading extends StatelessWidget {
  const _GateLoading();

  @override
  Widget build(BuildContext context) {
    return _GateScaffold(
      child: Center(
        child: StaggeredEntrance(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              AnimatedIconDot(
                icon: Icons.local_shipping,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(height: AppTheme.spaceMd),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium error state if the account status fails to resolve.
class _GateError extends StatelessWidget {
  const _GateError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _GateScaffold(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: StaggeredEntrance(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AnimatedIconDot(
                  icon: Icons.error_outline,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(height: AppTheme.spaceMd),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
