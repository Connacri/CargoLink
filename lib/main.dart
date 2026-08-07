import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_config.dart';
import 'providers.dart';
import 'client_home_screen.dart';
import 'booking_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/my_orders_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/tracking_screen.dart';
import 'screens/shipper_registration_screen.dart';
import 'screens/shipper_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize Firebase (for notifications)
  await initializeFirebase();

  runApp(const ProviderScope(child: CargoLinkApp()));
}

class CargoLinkApp extends ConsumerWidget {
  const CargoLinkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'CargoLink',
      theme: AppTheme.darkTheme,
      home: authState.when(
        data: (authData) {
          if (authData.isSignedIn) {
            return const HomeTabsScreen();
          } else {
            return const LoginScreen();
          }
        },
        loading: () => const LoadingScreen(),
        error: (error, stack) => ErrorScreen(error: error.toString()),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeTabsScreen(),
        '/booking': (context) {
          final shipmentId =
              ModalRoute.of(context)?.settings.arguments as String;
          return BookingScreen(shipmentId: shipmentId);
        },
        '/payment': (context) {
          final bookingId =
              ModalRoute.of(context)?.settings.arguments as String;
          return PaymentScreen(bookingId: bookingId);
        },
        '/tracking': (context) {
          final bookingId =
              ModalRoute.of(context)?.settings.arguments as String;
          return TrackingScreen(bookingId: bookingId);
        },
        '/my-orders': (context) => const MyOrdersScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/shipper-registration': (context) =>
            const ShipperRegistrationScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// ============================================================================
// LOADING SCREEN
// ============================================================================

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.local_shipping, size: 50, color: Colors.white),
            ),
            SizedBox(height: 24),
            Text(
              'CargoLink',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Chargement...',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ERROR SCREEN
// ============================================================================

class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Une erreur s\'est produite',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HOME TABS SCREEN
// ============================================================================

class HomeTabsScreen extends ConsumerWidget {
  const HomeTabsScreen({Key? key}) : super(key: key);

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
            icon: Icon(Icons.local_shipping),
            label: 'Mes Offres',
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