import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

// ============================================================================
// LOADING SCREEN
// ============================================================================

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

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
              child: Icon(Icons.flight_takeoff, size: 50, color: Colors.white),
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

class ErrorScreen extends StatefulWidget {
  final String error;

  const ErrorScreen({super.key, required this.error});

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.error));
    if (mounted) setState(() => _copied = true);
  }

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
              SelectableText(
                widget.error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: _copied ? null : _copy,
                icon: Icon(_copied ? Icons.check : Icons.copy),
                label: Text(_copied ? 'Copié' : 'Copier l\'erreur'),
              ),
              const SizedBox(height: 8),
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
// WEB ANDROID DOWNLOAD BANNER + POPUP
// ============================================================================

/// Shows a top banner (and a one-time popup) on the web build when the browser
/// runs on Android, prompting the user to download the native APK instead.
class WebAndroidDownloadBanner extends StatefulWidget {
  const WebAndroidDownloadBanner({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  /// True when this build runs inside an Android browser (web only).
  static bool get isAndroidWeb =>
      kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  State<WebAndroidDownloadBanner> createState() =>
      _WebAndroidDownloadBannerState();
}

class _WebAndroidDownloadBannerState extends State<WebAndroidDownloadBanner> {
  bool _dismissed = false;
  static bool _popupShown = false;

  @override
  void initState() {
    super.initState();
    if (WebAndroidDownloadBanner.isAndroidWeb && !_popupShown) {
      _popupShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showDownloadPopup();
      });
    }
  }

  Future<void> _openApk() async {
    final url = Uri.parse(AppConstants.androidApkUrl);
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir le lien de téléchargement'),
        ),
      );
    }
  }

  Future<void> _showDownloadPopup() async {
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) return;
    await showDialog<void>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Téléchargez l\'application CargoLink'),
        content: const Text(
          'Vous utilisez un téléphone Android. Téléchargez l\'application '
          'pour une meilleure expérience (notifications, caméra, vitesse).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Continuer sur le web'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _openApk();
            },
            child: const Text('Télécharger'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!WebAndroidDownloadBanner.isAndroidWeb || _dismissed) {
      return widget.child;
    }
    return Column(
      children: [
        _buildBanner(),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildBanner() {
    return Material(
      color: AppTheme.primaryDark,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd,
            vertical: AppTheme.spaceXs,
          ),
          child: Row(
            children: [
              const Icon(Icons.smartphone_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: AppTheme.spaceSm),
              const Expanded(
                child: Text(
                  'CargoLink disponible en application Android',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton(
                onPressed: _openApk,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                ),
                child:
                    const Text('Télécharger', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => setState(() => _dismissed = true),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
