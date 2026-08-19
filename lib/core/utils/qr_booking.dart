import 'dart:convert';

/// Encodes / decodes the content of a booking QR code.
///
/// The QR carries the client's tracking ref code plus the info needed by the
/// shipper (name, phone, account, destination) and the flight details (shipper
/// name, flight date, flight ref) so that scanning it lets the shipper confirm
/// collection in the country of origin and the client confirm the final
/// reception — or fall back to entering the ref code by hand.
class QrBookingPayload {
  static const int version = 1;

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
  });

  /// Human-readable tracking ref code derived from a booking id. Kept short
  /// enough to type by hand and ALPHANUMERIC ONLY (no hyphens or special
  /// characters) so it can be re-entered on any keyboard or scanned by a
  /// third-party reader.
  static String refCodeFor(String bookingId) {
    final cleaned =
        bookingId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    return cleaned.substring(0, cleaned.length > 10 ? 10 : cleaned.length);
  }

  /// Full alphanumeric tracking code stored on the booking (unique in DB).
  static String trackingCodeFor(String bookingId) {
    return bookingId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
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
