import 'package:flutter_test/flutter_test.dart';

import 'package:cargolink/core/utils/qr_booking.dart';

void main() {
  group('QrBookingPayload.refCodeFor', () {
    test('strips hyphens and special chars, uppercases, keeps 10 chars',
        () {
      final code = QrBookingPayload.refCodeFor(
        '123e4567-e89b-12d3-a456-426614174000',
      );
      expect(code, '123E4567E8');
      expect(RegExp(r'^[A-Z0-9]+$').hasMatch(code), isTrue);
      expect(code.contains('-'), isFalse);
    });

    test('never contains special characters', () {
      final code = QrBookingPayload.refCodeFor(
        'a-b_c.d/e:f*g@h!i',
      );
      expect(RegExp(r'^[A-Z0-9]+$').hasMatch(code), isTrue);
    });

    test('trackingCodeFor returns the full alphanumeric code', () {
      final code = QrBookingPayload.trackingCodeFor(
        '123e4567-e89b-12d3-a456-426614174000',
      );
      expect(code, '123E4567E89B12D3A456426614174000');
      expect(RegExp(r'^[A-Z0-9]+$').hasMatch(code), isTrue);
    });
  });

  group('QrBookingPayload encode/decode', () {
    test('roundtrips client, destination, product and flight details', () {
      const payload = QrBookingPayload(
        ref: 'ABC123DEFG',
        bookingId: '123e4567-e89b-12d3-a456-426614174000',
        name: 'Ahmed',
        phone: '+213 555 01 02',
        email: 'a@b.com',
        destination: 'Turquie → Alger',
        product: 'Vêtements',
        shipperName: 'Karim',
        flightDate: '19/08/2026',
        flightNumber: 'AH 4321',
      );

      final decoded = QrBookingPayload.decode(payload.encode());
      expect(decoded, isNotNull);
      expect(decoded!.ref, 'ABC123DEFG');
      expect(decoded.bookingId, payload.bookingId);
      expect(decoded.name, 'Ahmed');
      expect(decoded.phone, '+213 555 01 02');
      expect(decoded.email, 'a@b.com');
      expect(decoded.destination, 'Turquie → Alger');
      expect(decoded.product, 'Vêtements');
      expect(decoded.shipperName, 'Karim');
      expect(decoded.flightDate, '19/08/2026');
      expect(decoded.flightNumber, 'AH 4321');
    });

    test('isPlainRef accepts alphanumeric codes and rejects JSON', () {
      expect(QrBookingPayload.isPlainRef('ABC123DEFG'), isTrue);
      expect(QrBookingPayload.isPlainRef('abc123'), isTrue);
      expect(QrBookingPayload.isPlainRef('{"v":1}'), isFalse);
      expect(QrBookingPayload.isPlainRef('A-B-C'), isFalse);
    });
  });
}