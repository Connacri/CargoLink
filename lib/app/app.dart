import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/index.dart';
import '../screens/auth/account_gate_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/broadcast_screen.dart';
import '../screens/admin/feedback_inbox_screen.dart';
import '../screens/admin/founder_analytics_screen.dart';
import '../screens/admin/inventory_screen.dart';
import '../screens/admin/platform_settings_screen.dart';
import '../screens/client/booking_screen.dart';
import '../screens/client/booking_wizard_screen.dart';
import '../screens/client/my_orders_screen.dart';
import '../screens/client/payment_screen.dart';
import '../screens/client/tracking_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/shipper/shipper_registration_screen.dart';
import 'app_widgets.dart';
import 'home_tabs_screen.dart';

class CargoLinkApp extends ConsumerWidget {
  const CargoLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'CargoLink',
      theme: AppTheme.darkTheme,
      home: authState.when(
        data: (authData) {
          if (authData.isSignedIn) {
            if (!authData.emailVerified) {
              return const EmailVerificationScreen();
            }
            return const AccountGateScreen();
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
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeTabsScreen(),
        '/booking': (context) {
          final shipmentId =
              ModalRoute.of(context)?.settings.arguments as String;
          return BookingScreen(shipmentId: shipmentId);
        },
        '/booking-wizard': (context) {
          final shipmentId =
              ModalRoute.of(context)?.settings.arguments as String;
          return BookingWizardScreen(shipmentId: shipmentId);
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
        '/shipper-registration': (context) => const ShipperRegistrationScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/broadcast': (context) => const BroadcastScreen(),
        '/founder-analytics': (context) => const FounderAnalyticsScreen(),
        '/feedback-inbox': (context) => const FeedbackInboxScreen(),
        '/platform-settings': (context) => const PlatformSettingsScreen(),
        '/inventory': (context) => const InventoryScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
