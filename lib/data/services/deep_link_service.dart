import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestion des liens profonds CargoLink.
///
/// Formats supportés :
/// - `cargolink://offer/<shipmentId>` — ouvre l'écran de réservation
/// - `cargolink://referral/<code>` — pré-remplit le code parrain à l'inscription
class DeepLinkService {
  DeepLinkService();

  static const _pendingOfferKey = 'pending_offer_id';
  static const _pendingReferralKey = 'pending_referral_code';
  static const _pendingBookingKey = 'pending_booking_id';
  static final _offerRegex = RegExp(r'^offer/([A-Za-z0-9\-]+)$');
  static final _referralRegex = RegExp(r'^referral/([A-Z0-9]{6,14})$');
  static final _trackingRegex = RegExp(r'^tracking/([A-Za-z0-9\-]+)$');

  final AppLinks _links = AppLinks();
  StreamSubscription<Uri>? _sub;

  bool _initialized = false;

  /// Écoute les liens froids et chauds.
  void init({
    required void Function(String shipmentId) onOffer,
    required void Function(String code) onReferral,
    void Function(String bookingId)? onTracking,
  }) {
    if (_initialized) return;
    _initialized = true;

    Future<void> handle(Uri? uri) async {
      if (uri == null) return;
      final offerId = _extractOfferId(uri);
      if (offerId != null) {
        onOffer(offerId);
        return;
      }
      final trackingId = _extractTrackingId(uri);
      if (trackingId != null) {
        onTracking?.call(trackingId);
        return;
      }
      final referralCode = _extractReferralCode(uri);
      if (referralCode != null) {
        onReferral(referralCode);
      }
    }

    _links.getInitialLink().then(handle).catchError((_) => null);
    _sub = _links.uriLinkStream.listen(handle, onError: (_) {});
  }

  String? _extractOfferId(Uri uri) {
    if (uri.scheme == 'cargolink') {
      final path = uri.host.isEmpty ? uri.path : '${uri.host}${uri.path}';
      final m = _offerRegex.firstMatch(path.trim());
      if (m != null) return m.group(1);
    }
    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'offer') {
      return uri.pathSegments[1];
    }
    return null;
  }

  String? _extractReferralCode(Uri uri) {
    // cargolink://referral/<code>
    if (uri.scheme == 'cargolink') {
      final path = uri.host.isEmpty ? uri.path : '${uri.host}${uri.path}';
      final m = _referralRegex.firstMatch(path.trim());
      if (m != null) return m.group(1);
    }
    // https://…/referral/<code> (compatibilité future)
    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'referral') {
      return uri.pathSegments[1].toUpperCase();
    }
    return null;
  }

  String? _extractTrackingId(Uri uri) {
    // cargolink://tracking/<bookingId>
    if (uri.scheme == 'cargolink') {
      final path = uri.host.isEmpty ? uri.path : '${uri.host}${uri.path}';
      final m = _trackingRegex.firstMatch(path.trim());
      if (m != null) return m.group(1);
    }
    // https://…/tracking/<bookingId> (compatibilité future)
    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'tracking') {
      return uri.pathSegments[1];
    }
    return null;
  }

  // ── Offres ──

  Future<void> savePendingOffer(String shipmentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingOfferKey, shipmentId);
  }

  Future<String?> consumePendingOffer() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_pendingOfferKey);
    if (id != null && id.isNotEmpty) {
      await prefs.remove(_pendingOfferKey);
      return id;
    }
    return null;
  }

  // ── Parrainage ──

  Future<void> savePendingReferralCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingReferralKey, code.toUpperCase());
  }

  Future<String?> consumePendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_pendingReferralKey);
    if (code != null && code.isNotEmpty) {
      await prefs.remove(_pendingReferralKey);
      return code;
    }
    return null;
  }

  // ── Booking (notification push / deep link) ──

  Future<void> savePendingBooking(String bookingId) async {
    if (bookingId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingBookingKey, bookingId);
  }

  Future<String?> consumePendingBooking() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_pendingBookingKey);
    if (id != null && id.isNotEmpty) {
      await prefs.remove(_pendingBookingKey);
      return id;
    }
    return null;
  }

  /// Construit l'URL de deep link pour un code parrain.
  static String referralLink(String code) =>
      'cargolink://referral/$code';

  void dispose() {
    _sub?.cancel();
  }
}
