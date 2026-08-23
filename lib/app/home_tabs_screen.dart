import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/index.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/super_admin_dashboard_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/client/client_home_screen.dart';
import '../screens/client/my_orders_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/shipper/shipper_dashboard_screen.dart';
import '../screens/shipper/shipper_finance_screen.dart';
import 'app_widgets.dart';

// ============================================================================
// HOME TABS SCREEN
// ============================================================================

class HomeTabsScreen extends ConsumerWidget {
  const HomeTabsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(navigationIndexProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Quand l'utilisateur change de rôle, le nombre d'onglets change (client 3,
    // expéditeur 4) : remettre l'onglet actif à zéro pour ne jamais garder un
    // index hors limites (crash BottomNavigationBar).
    ref.listen(currentUserProvider, (prev, next) {
      final oldRole = prev?.valueOrNull?.role;
      final newRole = next.valueOrNull?.role;
      if (oldRole != null && oldRole != newRole) {
        ref.read(navigationIndexProvider.notifier).state = 0;
      }
    });

    return currentUser.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        // Route based on user role
        switch (user.role) {
          case 'client':
            return _buildClientTabs(context, ref, navIndex);
          case 'shipper':
            return _buildShipperTabs(context, ref, navIndex);
          case 'admin':
            return const AdminDashboardScreen();
          case 'super_admin':
            return const SuperAdminDashboardScreen();
          default:
            return const LoginScreen();
        }
      },
      loading: () => const LoadingScreen(),
      error: (error, stack) => ErrorScreen(error: error.toString()),
    );
  }

  Widget _buildClientTabs(
    BuildContext context,
    WidgetRef ref,
    int navIndex,
  ) {
    // Borne défensive : 3 onglets client (0..2).
    final index = navIndex.clamp(0, 2);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          ClientHomeScreen(),
          MyOrdersScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(
            icon: _ProfileTabIcon(selected: index == 2),
            activeIcon: const _ProfileTabIcon(selected: true),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildShipperTabs(
    BuildContext context,
    WidgetRef ref,
    int navIndex,
  ) {
    // Borne défensive : 4 onglets expéditeur (0..3).
    final index = navIndex.clamp(0, 3);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          ShipperDashboardScreen(),
          ActiveShipmentsScreen(),
          ShipperFinanceScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.flight_takeoff),
            label: 'Mes Offres',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Finance',
          ),
          BottomNavigationBarItem(
            icon: _ProfileTabIcon(
              selected: index == 3,
              showVerificationBadge: true,
            ),
            activeIcon: const _ProfileTabIcon(
              selected: true,
              showVerificationBadge: true,
            ),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Onglet « Profil » de la bottom bar : photo de profil de l'utilisateur
/// (icône par défaut si aucune), avec pastille d'état de vérification pour
/// les expéditeurs (vert = vérifié, orange = en attente, rouge = refusé).
class _ProfileTabIcon extends ConsumerWidget {
  const _ProfileTabIcon({required this.selected, this.showVerificationBadge});

  final bool selected;
  final bool? showVerificationBadge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final shipper =
        showVerificationBadge == true
            ? ref.watch(currentShipperProvider).valueOrNull
            : null;

    final Color tint =
        selected ? Theme.of(context).colorScheme.primary : Colors.grey;
    final String? photoUrl = user?.profilePictureUrl;

    Widget avatar;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      avatar = ClipOval(
        child: Image.network(
          photoUrl,
          width: 26,
          height: 26,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.person, size: 24, color: tint),
        ),
      );
    } else {
      avatar = Icon(Icons.person, size: 24, color: tint);
    }
    if (selected && (photoUrl?.isNotEmpty ?? false)) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: tint, width: 2),
        ),
        child: avatar,
      );
    }

    // Pastille de vérification (expéditeur uniquement).
    IconData? badgeIcon;
    Color badgeColor;
    switch (shipper?.verificationStatus) {
      case 'verified':
        badgeIcon = Icons.check_circle_rounded;
        badgeColor = const Color(0xFF22C55E);
      case 'rejected':
        badgeIcon = Icons.cancel_rounded;
        badgeColor = const Color(0xFFEF4444);
      case 'pending':
        badgeIcon = Icons.schedule_rounded;
        badgeColor = const Color(0xFFF59E0B);
      default:
        badgeIcon = null;
        badgeColor = Colors.transparent;
    }

    return SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: avatar),
          if (badgeIcon != null)
            Positioned(
              right: -3,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(badgeIcon, size: 13, color: badgeColor),
              ),
            ),
        ],
      ),
    );
  }
}
