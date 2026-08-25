import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/offer_ticket_card.dart';
import '../models/models.dart';

/// Partage social d'une offre : génère l'image « billet d'avion » de l'offre
/// et ouvre la feuille de partage native avec un lien web (accessible aux
/// non-inscrits) + lien deep link pour ouverture directe dans l'app.
class OfferShareService {
  static const _deepLinkScheme = 'cargolink';
  static const _webBaseUrl =
      'https://connacri.github.io/CargoLink/offer.html';
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.cargolink.dz.cargolink';

  /// Lien profond direct vers une offre (si l'app est installée).
  static String deepLinkFor(String shipmentId) =>
      '$_deepLinkScheme://offer/$shipmentId';

  /// Lien web fallback (accessible aux non-inscrits, ouvre la page de partage).
  static String webLinkFor(String shipmentId) =>
      '$_webBaseUrl?id=$shipmentId';

  Future<void> shareOffer(BuildContext context, Shipment shipment) async {
    final shipper = shipment.shipper;
    final bytes = await _captureTicket(
      context,
      OfferTicketCard(
        shipperName: shipper?.user?.fullName ?? 'Expéditeur vérifié',
        origin: shipment.originCountry,
        destination: shipment.destinationCity,
        airline: shipment.airline,
        flightNumber: shipment.flightNumber,
        departureDate: shipment.departureDate,
        arrivalDate: shipment.arrivalDate,
        pricePerKg: shipment.pricePerKg,
        availableKg: shipment.remainingWeightKg,
        currency: AppConstants.defaultCurrency,
      ),
    );

    final webUrl = webLinkFor(shipment.id);
    final text = '✈️ ${shipment.originCountry} → ${shipment.destinationCity} '
       'à partir de ${shipment.pricePerKg.toStringAsFixed(0)} '
        '${AppConstants.defaultCurrency}/kg avec CargoLink !\n'
        'Voir l\'offre : $webUrl\n'
        'Télécharger l\'app : $_playStoreUrl';

    final XFile file;
    if (bytes != null) {
      file = XFile.fromData(
        bytes,
        name: 'cargolink-offre-${shipment.id.substring(0, 8)}.png',
        mimeType: 'image/png',
      );
      await Share.shareXFiles([file], text: text);
    } else {
      await Share.share(text);
    }
  }

  /// Rend [ticket] hors écran dans l'Overlay racine et le capture en PNG.
  Future<Uint8List?> _captureTicket(BuildContext context, Widget ticket) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final key = GlobalKey();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -2000,
        top: 0,
        child: RepaintBoundary(key: key, child: ticket),
      ),
    );
    overlay.insert(entry);
    try {
      // Deux frames pour garantir le layout/peinture du billet hors écran.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final boundary = key.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return null;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    } finally {
      entry.remove();
    }
  }
}
