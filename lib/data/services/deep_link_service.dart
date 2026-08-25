import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestion des liens profonds CargoLink.
///
/// Format supporté : `cargolink://offer/<shipmentId>` — ouvre directement
/// l'écran de réservation de l'offre. Si l'utilisateur n'est pas encore
/// connecté, l'id est mis en file d'attente et consommé juste après le
/// premier login (voir [consumePendingOffer]).
class DeepLinkService {
  DeepLinkService();

  static const _pendingOfferKey = 'pending_offer_id';
  static final _pendingRegex = RegExp(r'^offer/([A-Za-z0-9\-]+)$');

  final AppLinks _links = AppLinks();
  StreamSubscription<Uri>? _sub;

  bool _initialized = false;

  /// Écoute les liens froids (app ouverte par le lien) et chauds (liens
  /// reçus pendant que l'app tourne). [onOffer] reçoit l'id d'offre.
  void init({required void Function(String shipmentId) onOffer}) {
    if (_initialized) return;
    _initialized = true;

    Future<void> handle(Uri? uri) async {
      if (uri == null) return;
      final id = _extractOfferId(uri);
      if (id != null) onOffer(id);
    }

    _links.getInitialLink().then(handle).catchError((_) => null);
    _sub = _links.uriLinkStream.listen(handle, onError: (_) {});
  }

  String? _extractOfferId(Uri uri) {
    // cargolink://offer/<id>
    if (uri.scheme == 'cargolink') {
      final path = uri.host.isEmpty ? uri.path : '${uri.host}${uri.path}';
      final m = _pendingRegex.firstMatch(path.trim());
      if (m != null) return m.group(1);
    }
    // https://…/offer/<id> (compatibilité future Android App Links)
    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'offer') {
      return uri.pathSegments[1];
    }
    return null;
  }

  /// Met l'offre en attente (utilisateur non connecté).
  Future<void> savePendingOffer(String shipmentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingOfferKey, shipmentId);
  }

  /// Récupère (et consomme) l'offre en attente — appelé après login/signup.
  Future<String?> consumePendingOffer() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_pendingOfferKey);
    if (id != null && id.isNotEmpty) {
      await prefs.remove(_pendingOfferKey);
      return id;
    }
    return null;
  }

  void dispose() {
    _sub?.cancel();
  }
}
