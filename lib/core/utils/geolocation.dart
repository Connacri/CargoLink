import 'package:geolocator/geolocator.dart';

/// Résultat de géolocalisation simplifié pour le workflow « arrivé à
/// destination » : position GPS + libellé de lieu (ville détectée ou vide).
class LocationResult {
  final double latitude;
  final double longitude;
  final String? label;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.label,
  });
}

/// Tente d'obtenir la position GPS actuelle (permissions gérées). Retourne
/// `null` si l'utilisateur refuse ou si la localisation est indisponible.
Future<LocationResult?> getCurrentLocation() async {
  try {
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 12),
    );

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  } catch (_) {
    return null;
  }
}