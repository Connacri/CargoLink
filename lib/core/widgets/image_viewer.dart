import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Opens a full-screen, pinch-to-zoom viewer for a network image.
///
/// Used by the founder/admin verification flow to inspect KYC photos
/// (passport + live selfie) at full size before approving a shipper.
Future<void> showFullScreenImage(
  BuildContext context, {
  required String imageUrl,
  String? title,
}) {
  return showDialog<void>(
    context: context,
    useRootNavigator: false,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text(
                      'Aperçu indisponible',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceSm),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Fermer',
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  if (title != null)
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
