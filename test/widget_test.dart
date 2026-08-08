import 'package:flutter_test/flutter_test.dart';

import 'package:cargolink/data/models/models.dart';

void main() {
  test('User.fromJson parses a valid payload', () {
    final user = User.fromJson({
      'id': 'id-1',
      'email': 'test@example.com',
      'phone': '+213700000000',
      'full_name': 'Test User',
      'role': 'client',
      'created_at': '2026-01-01T10:00:00.000Z',
      'updated_at': '2026-01-01T10:00:00.000Z',
    });

    expect(user.id, 'id-1');
    expect(user.role, 'client');
    expect(user.fullName, 'Test User');
  });

  test('Shipment.isActive respects status and arrival date', () {
    final now = DateTime.now();
    final shipment = Shipment.fromJson({
      'id': 'ship-1',
      'shipper_id': 'shipper-1',
      'origin_country': 'Turquie',
      'destination_city': 'Alger',
      'available_weight_kg': 50,
      'reserved_weight_kg': 10,
      'price_per_kg': 1000,
      'departure_date': now.add(const Duration(days: 1)).toIso8601String(),
      'arrival_date': now.add(const Duration(days: 7)).toIso8601String(),
      'status': 'active',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    expect(shipment.isActive, isTrue);
    expect(shipment.remainingWeightKg, 40);
  });
}