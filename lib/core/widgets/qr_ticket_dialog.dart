import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';

import '../../data/models/models.dart';
import '../theme/app_theme.dart';
import '../utils/qr_booking.dart';
import '../utils/web_download_stub.dart'
    if (dart.library.js_interop) '../utils/web_download.dart';
import 'qr_booking_ticket.dart';
import 'image_viewer.dart';

/// Affiche le billet QR d'une commande existante et permet de le
/// ré-enregistrer (même code de suivi que celui généré à la réservation —
/// jamais régénéré).
///
/// [onViewDetail] optionnel : appelé quand l'utilisateur appuie sur « Voir le
/// détail » (pour ouvrir l'écran complet de la commande propre à chaque rôle).
Future<void> showQrTicketDialog(
  BuildContext context,
  Booking booking, {
  VoidCallback? onViewDetail,
}) {
  final client = booking.client;
  final shipment = booking.shipment;
  final payload = QrBookingPayload(
    ref: booking.trackingNumber?.isNotEmpty == true
        ? booking.trackingNumber!
        : QrBookingPayload.refCodeFor(booking.id),
    bookingId: booking.id,
    name: client?.fullName ?? '',
    phone: client?.phone ?? '',
    email: client?.email ?? '',
    destination:
        '${shipment?.originCountry ?? '?'} → ${shipment?.destinationCity ?? '?'}',
    product: booking.productName,
    shipperName: shipment?.shipper?.user?.fullName ?? '',
    flightDate: shipment?.departureDate != null
        ? _formatDate(shipment!.departureDate)
        : '',
    flightNumber: shipment?.flightNumber ?? '',
    airline: shipment?.airline ?? '',
  );

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _QrTicketDialog(
      payload: payload,
      booking: booking,
      onViewDetail: onViewDetail,
    ),
  );
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

class _QrTicketDialog extends StatefulWidget {
  const _QrTicketDialog({
    required this.payload,
    required this.booking,
    this.onViewDetail,
  });

  final QrBookingPayload payload;
  final Booking booking;
  final VoidCallback? onViewDetail;

  @override
  State<_QrTicketDialog> createState() => _QrTicketDialogState();
}

class _QrTicketDialogState extends State<_QrTicketDialog> {
  final GlobalKey _ticketKey = GlobalKey();
  bool _saving = false;

  Future<void> _save() async {
    final boundary = _ticketKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    setState(() => _saving = true);
    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Impossible de générer l\'image');
      final bytes = byteData.buffer.asUint8List();
      final fileName =
          'cargolink-reservation-${widget.payload.bookingId}';
      if (kIsWeb) {
        downloadBytesOnWeb(bytes, '$fileName.png');
      } else {
        if (!await Gal.hasAccess()) await Gal.requestAccess();
        await Gal.putImageBytes(bytes, name: fileName);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Billet enregistre dans la galerie.'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Echec : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: AppTheme.primaryLighter,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── TICKET (zone d'enregistrement uniquement) ───
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: RepaintBoundary(
                  key: _ticketKey,
                  child: QrBookingTicket(payload: widget.payload),
                ),
              ),
              const SizedBox(height: AppTheme.spaceXs),
              // ─── PHOTOS PRODUIT (agrandissables, multi) ───
              if (widget.booking.productPhotosUrl != null &&
                  widget.booking.productPhotosUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProductPhotos(booking: widget.booking),
                      const SizedBox(height: AppTheme.spaceMd),
                    ],
                  ),
                ),
              // ─── ACTIONS ───
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceMd),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Fermer'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 18),
                        label: Text(
                            _saving ? 'Enregistrement...' : 'Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onViewDetail != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMd,
                    0,
                    AppTheme.spaceMd,
                    AppTheme.spaceMd,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onViewDetail!();
                      },
                      child: const Text('Voir le détail complet'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Photos produit de la commande, cliquables pour ouverture plein écran.
/// Plusieurs photos → bande horizontale défilable ; une seule → image seule.
class _ProductPhotos extends StatelessWidget {
  const _ProductPhotos({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final photos = booking.productPhotosUrl!
        .where((u) => u.isNotEmpty)
        .toList(growable: false);
    if (photos.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spaceSm),
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => showFullScreenImage(
              context,
              imageUrl: photos[i],
              title: booking.productName,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Image.network(
                photos[i],
                width: 120,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 120,
                  height: 140,
                  color: AppTheme.surfaceColor,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.textMutedColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
