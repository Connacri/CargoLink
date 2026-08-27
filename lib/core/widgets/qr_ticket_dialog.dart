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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── TICKET ───
              RepaintBoundary(
                key: _ticketKey,
                child: QrBookingTicket(payload: widget.payload),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              // ─── INSTRUCTION ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                      color: AppTheme.accentColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.print_outlined,
                            size: 16, color: AppTheme.accentColor),
                        const SizedBox(width: AppTheme.spaceSm),
                        Expanded(
                          child: Text(
                            'IMPORTANT',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Imprimez ce billet et envoyez-le au fournisseur afin '
                      'qu\'il imprime ce code et le colle sur le colis / la '
                      'marchandise, pour ne pas le perdre parmi les colis et '
                      'faciliter la livraison.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    if (widget.payload.flightDate.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.event_rounded,
                              size: 14, color: AppTheme.accentColor),
                          const SizedBox(width: AppTheme.spaceSm),
                          Expanded(
                            child: Text(
                              'Date du vol : ${widget.payload.flightDate}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              // ─── ACTIONS ───
              Row(
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
            ],
          ),
        ),
      ),
    );
  }
}
