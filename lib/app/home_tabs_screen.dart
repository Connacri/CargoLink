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
    return Scaffold(
      body: IndexedStack(
        index: navIndex,
        children: const [
          ClientHomeScreen(),
          MyOrdersScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
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
    return Scaffold(
      body: IndexedStack(
        index: navIndex,
        children: const [
          ShipperDashboardScreen(),
          ActiveShipmentsScreen(),
          ShipperFinanceScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight_takeoff),
            label: 'Mes Offres',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Finance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
