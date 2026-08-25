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

/// Affiche le billet QR d'une commande existante et permet de le
/// ré-enregistrer (même code de suivi que celui généré à la réservation —
/// jamais régénéré).
Future<void> showQrTicketDialog(BuildContext context, Booking booking) {
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
    builder: (dialogContext) => _QrTicketDialog(payload: payload),
  );
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

class _QrTicketDialog extends StatefulWidget {
  const _QrTicketDialog({required this.payload});

  final QrBookingPayload payload;

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
            content: Text('Confirmation enregistrée.'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'enregistrement: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth * 0.85).clamp(300.0, 480.0);

    return Dialog(
      backgroundColor: AppTheme.backgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Mon QR code', style: AppTheme.h3),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              RepaintBoundary(
                key: _ticketKey,
                child: QrBookingTicket(payload: widget.payload),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              FilledButton.icon(
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
                label: Text(_saving
                    ? 'Préparation…'
                    : (kIsWeb
                        ? 'Télécharger (PNG)'
                        : 'Enregistrer dans la galerie')),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
