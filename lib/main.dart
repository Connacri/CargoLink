import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_config.dart';
import 'providers.dart';
import 'client_home_screen.dart';
import 'booking_screen.dart';
// Import other screens as needed

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
          if (authData.session != null) {
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(
                Icons.local_shipping,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'CargoLink',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chargement...',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
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

  const ErrorScreen({
    Key? key,
    required this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
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
        children: [
          const ClientHomeScreen(),
          const MyOrdersScreen(),
          const ProfileScreen(),
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
        children: [
          const ShipperDashboardScreen(),
          const ActiveShipmentsScreen(),
          const ProfileScreen(),
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
            label: 'Mes Shipments',
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

// ============================================================================
// PLACEHOLDER SCREENS (À implémenter)
// ============================================================================

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Écran de Connexion'),
      ),
    );
  }
}

class SignupScreen extends StatelessWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Écran d\'inscription'),
      ),
    );
  }
}

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Commandes')),
      body: const Center(
        child: Text('Écran Mes Commandes'),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: const Center(
        child: Text('Écran Profil'),
      ),
    );
  }
}

class PaymentScreen extends StatelessWidget {
  final String bookingId;

  const PaymentScreen({Key? key, required this.bookingId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: Center(
        child: Text('Écran Paiement pour booking: $bookingId'),
      ),
    );
  }
}

class TrackingScreen extends StatelessWidget {
  final String bookingId;

  const TrackingScreen({Key? key, required this.bookingId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suivi')),
      body: Center(
        child: Text('Écran Suivi pour booking: $bookingId'),
      ),
    );
  }
}

class ShipperRegistrationScreen extends StatelessWidget {
  const ShipperRegistrationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription Shipper')),
      body: const Center(
        child: Text('Écran Inscription Shipper'),
      ),
    );
  }
}

class ShipperDashboardScreen extends StatelessWidget {
  const ShipperDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: const Center(
        child: Text('Tableau de bord Shipper'),
      ),
    );
  }
}

class ActiveShipmentsScreen extends StatelessWidget {
  const ActiveShipmentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Shipments')),
      body: const Center(
        child: Text('Écran Mes Shipments'),
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: const Center(
        child: Text('Tableau de bord Admin'),
      ),
    );
  }
}
