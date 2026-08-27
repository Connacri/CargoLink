import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/feedback_launcher.dart';
import '../providers/index.dart';
import '../screens/auth/account_gate_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/ads_screen.dart';
import '../screens/admin/broadcast_screen.dart';
import '../screens/admin/feedback_inbox_screen.dart';
import '../screens/admin/founder_analytics_screen.dart';
import '../screens/admin/inventory_screen.dart';
import '../screens/admin/platform_settings_screen.dart';
import '../screens/client/booking_screen.dart';
import '../screens/client/booking_wizard_screen.dart';
import '../screens/client/my_orders_screen.dart';
import '../screens/client/my_parcels_screen.dart';
import '../screens/client/offer_detail_screen.dart';
import '../screens/client/payment_screen.dart';
import '../screens/client/tracking_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/client/delivery_request_screen.dart';
import '../screens/shipper/delivery_browse_screen.dart';
import '../screens/shipper/shipper_ads_screen.dart';
import '../screens/shipper/shipper_registration_screen.dart';
import 'app_widgets.dart';
import 'home_tabs_screen.dart';

/// Global navigator key used to overlay app-level popups (e.g. the Android
/// download dialog on the web) above every route.
final appNavigatorKey = GlobalKey<NavigatorState>();

class CargoLinkApp extends ConsumerWidget {
  const CargoLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'CargoLink',
      theme: AppTheme.darkTheme,
      navigatorKey: appNavigatorKey,
      locale: const Locale('fr'),
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => WebAndroidDownloadBanner(
        navigatorKey: appNavigatorKey,
        child: Stack(
          children: [
            child ?? const SizedBox.shrink(),
            // Écoute des liens profonds (cargolink://offer/<id>).
            const _DeepLinkListener(),
      // FAB « Feedback » global — positionnée juste au-dessus de la
      // bottom navigation bar pour ne pas la masquer.
      const Positioned(
        right: 16,
        bottom: 76,
        child: GlobalFeedbackFab(),
      ),
          ],
        ),
      ),
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
        '/offer-detail': (context) {
          final shipmentId =
              ModalRoute.of(context)?.settings.arguments as String;
          return OfferDetailScreen(shipmentId: shipmentId);
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
        '/my-parcels': (context) => const MyParcelsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/shipper-registration': (context) => const ShipperRegistrationScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/broadcast': (context) => const BroadcastScreen(),
        '/ads': (context) => const AdsScreen(),
        '/founder-analytics': (context) => const FounderAnalyticsScreen(),
        '/feedback-inbox': (context) => const FeedbackInboxScreen(),
        '/platform-settings': (context) => const PlatformSettingsScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/my-ads': (context) => const ShipperAdsScreen(),
        '/delivery-requests': (context) => const DeliveryRequestScreen(),
        '/delivery-browse': (context) => const DeliveryBrowseScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Écoute les deep links entrants et route vers l'offre ciblée :
/// - utilisateur connecté → écran de réservation directement ;
/// - sinon → l'id est mis en file d'attente, consommé après login
///   (voir [HomeTabsScreen]).
class _DeepLinkListener extends ConsumerStatefulWidget {
  const _DeepLinkListener();

  @override
  ConsumerState<_DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends ConsumerState<_DeepLinkListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deepLinkServiceProvider).init(
        onOffer: (shipmentId) {
          final nav = appNavigatorKey.currentState;
          if (nav == null) return;
          final signedIn =
              ref.read(authServiceProvider).currentUserId != null;
          if (signedIn) {
            nav.pushNamed('/booking-wizard', arguments: shipmentId);
          } else {
            ref.read(deepLinkServiceProvider).savePendingOffer(shipmentId);
          }
        },
        onReferral: (code) {
          final nav = appNavigatorKey.currentState;
          if (nav == null) return;
          final signedIn =
              ref.read(authServiceProvider).currentUserId != null;
          if (!signedIn) {
            // Sauvegarder le code et le consommer après inscription
            ref.read(deepLinkServiceProvider).savePendingReferralCode(code);
            nav.pushNamedAndRemoveUntil('/signup', (route) => false,
                arguments: code);
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
