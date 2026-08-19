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
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: payload.encode(),
            version: QrVersions.auto,
            size: 160,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppTheme.textPrimaryColor,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          const Text('Réf de suivi', style: AppTheme.caption),
          const SizedBox(height: AppTheme.spaceXs),
          SelectableText(
            payload.ref,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          const Divider(color: AppTheme.dividerColor, height: 1),
          const SizedBox(height: AppTheme.spaceSm),
          _row(Icons.person_outline, 'Client', payload.name),
          _row(Icons.phone_outlined, 'Téléphone', payload.phone),
          _row(Icons.account_circle_outlined, 'Compte', payload.email),
          _row(
            Icons.location_on_outlined,
            'Destination',
            payload.destination,
          ),
          if (payload.product.isNotEmpty)
            _row(Icons.inventory_2_outlined, 'Produit', payload.product),
          const Divider(color: AppTheme.dividerColor, height: 1),
          const SizedBox(height: AppTheme.spaceXs),
          if (payload.shipperName.isNotEmpty)
            _row(
              Icons.storefront_outlined,
              'Expéditeur',
              payload.shipperName,
            ),
          if (payload.flightDate.isNotEmpty)
            _row(
              Icons.event_rounded,
              'Date du vol',
              payload.flightDate,
            ),
          if (payload.flightNumber.isNotEmpty)
            _row(
              Icons.flight_takeoff_rounded,
              'Réf. vol',
              payload.flightNumber,
            ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
          const SizedBox(width: AppTheme.spaceSm),
          Expanded(
            child: Text(
              '$label : ',
              style: AppTheme.caption,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTheme.body,
            ),
          ),
        ],
      ),
    );
  }
}
