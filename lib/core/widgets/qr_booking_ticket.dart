import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_theme.dart';
import '../utils/qr_booking.dart';

/// Booking "ticket": the QR code carries the client's tracking ref code, and
/// below it the client details (name, phone, account, destination), the
/// shipper + flight info (shipper name, flight date, flight ref) plus the ref
/// code as plain text. A shipper scans it — or types the ref in — to confirm
/// collection in the country of origin; the client does the same to confirm
/// the final reception.
class QrBookingTicket extends StatelessWidget {
  const QrBookingTicket({super.key, required this.payload});

  final QrBookingPayload payload;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── HEADER (gradient) ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceLg),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusLg),
                topRight: Radius.circular(AppTheme.radiusLg),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.confirmation_num_rounded,
                        color: Colors.white.withValues(alpha: 0.85), size: 18),
                    const SizedBox(width: AppTheme.spaceSm),
                    Text(
                      'CARGOLINK',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSm),
                const Text(
                  'Billet de Reservation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  payload.product,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // ─── QR CODE ───
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                    color: AppTheme.dividerColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: payload.encode(),
                    version: QrVersions.auto,
                    size: 150,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppTheme.primaryDark,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  const Text('NUMERO DE SUIVI',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppTheme.textSecondaryColor)),
                  const SizedBox(height: 2),
                  SelectableText(
                    payload.ref,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── DASHED DIVIDER ───
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
            child: Row(
              children: List.generate(
                40,
                (i) => Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    color: i.isEven
                        ? AppTheme.dividerColor
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),

          // ─── CLIENT DETAILS ───
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
            child: Column(
              children: [
                if (payload.name.isNotEmpty)
                  _ticketRow(Icons.person_outline_rounded, 'Client',
                      payload.name),
                if (payload.phone.isNotEmpty)
                  _ticketRow(
                      Icons.phone_outlined, 'Telephone', payload.phone),
                if (payload.email.isNotEmpty)
                  _ticketRow(Icons.email_outlined, 'Compte', payload.email),
                _ticketRow(Icons.location_on_outlined, 'Destination',
                    payload.destination),
              ],
            ),
          ),

          // ─── DASHED DIVIDER ───
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
            child: Row(
              children: List.generate(
                40,
                (i) => Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    color: i.isEven
                        ? AppTheme.dividerColor
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),

          // ─── SHIPPER / FLIGHT DETAILS ───
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
            child: Column(
              children: [
                if (payload.shipperName.isNotEmpty)
                  _ticketRow(Icons.storefront_outlined, 'Expediteur',
                      payload.shipperName),
                if (payload.flightDate.isNotEmpty)
                  _ticketRow(
                      Icons.event_rounded, 'Vol le', payload.flightDate),
                if (payload.flightNumber.isNotEmpty)
                  _ticketRow(
                    Icons.flight_takeoff_rounded,
                    'Ref. vol',
                    payload.airline.isNotEmpty
                        ? '${payload.airline} · ${payload.flightNumber}'
                        : payload.flightNumber,
                  ),
              ],
            ),
          ),

          // ─── DASHED DIVIDER ───
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
            child: Row(
              children: List.generate(
                40,
                (i) => Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    color: i.isEven
                        ? AppTheme.dividerColor
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),

          // ─── PRODUCT ───
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceMd),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: AppTheme.spaceSm),
                  Expanded(
                    child: Text(
                      payload.product,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── INSTRUCTION (imprimer + envoyer au fournisseur) ───
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceMd),
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border:
                  Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3)),
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
                Text(
                  'Imprimez ce billet et envoyez-le au fournisseur afin '
                  'qu\'il imprime ce code et le colle sur le colis / la '
                  'marchandise, pour ne pas le perdre parmi les colis et '
                  'faciliter la livraison.',
                  style: AppTheme.body.copyWith(
                    fontSize: 12.5,
                    color: AppTheme.textPrimaryColor,
                    height: 1.35,
                  ),
                ),
                if (payload.flightDate.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.event_rounded,
                          size: 14, color: AppTheme.accentColor),
                      const SizedBox(width: AppTheme.spaceSm),
                      Expanded(
                        child: Text(
                          'Date du vol : ${payload.flightDate}',
                          style: AppTheme.body.copyWith(
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
        ],
      ),
    );
  }

  Widget _ticketRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondaryColor),
          const SizedBox(width: 8),
          SizedBox(
            width: 76,
            child: Text(
              label,
              style:
                  AppTheme.caption.copyWith(color: AppTheme.textMutedColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
