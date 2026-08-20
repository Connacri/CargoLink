import 'dart:convert';
import 'dart:math';

/// Encodes / decodes the content of a booking QR code.
///
/// The QR carries the client's tracking ref code plus the info needed by the
/// shipper (name, phone, account, destination) and the flight details (shipper
/// name, flight date, flight ref) so that scanning it lets the shipper confirm
/// collection in the country of origin and the client confirm the final
/// reception — or fall back to entering the ref code by hand.
class QrBookingPayload {
  static const int version = 1;

  /// Alphabet without ambiguous characters (0/O, 1/I/L) so the code is easy to
  /// read aloud and to type. 32 symbols ^ 10 chars ≈ 1.1 × 10^15 combinations.
  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Default length of a tracking code (within the user-required 6-14 range).
  static const int refLength = 10;

  final String ref;
  final String bookingId;
  final String name;
  final String phone;
  final String email;
  final String destination;
  final String product;
  final String shipperName;
  final String flightDate;
  final String flightNumber;
  final String airline;

  const QrBookingPayload({
    required this.ref,
    required this.bookingId,
    required this.name,
    required this.phone,
    required this.email,
    required this.destination,
    required this.product,
    this.shipperName = '',
    this.flightDate = '',
    this.flightNumber = '',
    this.airline = '',
  });

  /// Human-readable tracking ref code derived from a booking id. Kept short
  /// enough to type by hand and ALPHANUMERIC ONLY (no hyphens or special
  /// characters). Used as a fallback when no dedicated tracking number exists.
  static String refCodeFor(String bookingId) {
    final cleaned =
        bookingId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    return cleaned.substring(0, cleaned.length > 10 ? 10 : cleaned.length);
  }

  /// Full alphanumeric tracking code derived from the booking id (used as a
  /// deterministic fallback by the database trigger when no code is supplied).
  static String trackingCodeFor(String bookingId) {
    return bookingId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  }

  /// Generates a random alphanumeric tracking code (no special characters,
  /// no ambiguous glyphs) of [length] chars — default 10, within the required
  /// 6-14 range. Uniqueness is enforced against the `bookings` table at insert.
  static String randomRefCode({int length = refLength}) {
    final rng = Random.secure();
    return List.generate(length, (_) => _alphabet[rng.nextInt(_alphabet.length)])
        .join();
  }

  String encode() => jsonEncode({
        'v': version,
        'ref': ref,
        'id': bookingId,
        'name': name,
        'phone': phone,
        'email': email,
        'dest': destination,
        'prod': product,
        'ship': shipperName,
        'fdate': flightDate,
        'fnum': flightNumber,
        'air': airline,
      });

  static QrBookingPayload? decode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    try {
      final map = jsonDecode(trimmed);
      if (map is! Map<String, dynamic>) return null;
      if (map['v'] != version || map['id'] is! String) return null;
      return QrBookingPayload(
        ref: (map['ref'] as String?) ?? '',
        bookingId: map['id'] as String,
        name: (map['name'] as String?) ?? '',
        phone: (map['phone'] as String?) ?? '',
        email: (map['email'] as String?) ?? '',
        destination: (map['dest'] as String?) ?? '',
        product: (map['prod'] as String?) ?? '',
        shipperName: (map['ship'] as String?) ?? '',
        flightDate: (map['fdate'] as String?) ?? '',
        flightNumber: (map['fnum'] as String?) ?? '',
        airline: (map['air'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// True when the scanned text looks like a plain tracking ref code rather
  /// than a JSON payload (e.g. `ABC123DEFG`).
  static bool isPlainRef(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('{')) return false;
    return RegExp(r'^[A-Za-z0-9]{4,32}$').hasMatch(trimmed);
  }
}
