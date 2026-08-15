import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cargolink/components/shipper_card.dart';
import 'package:cargolink/components/tracking_timeline.dart';
import 'package:cargolink/components/revenue_bar_chart.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ShipperCard', () {
    testWidgets('renders name, availability and book button', (tester) async {
      var booked = false;
      await tester.pumpWidget(_wrap(ShipperCard(
        shipperId: 's1',
        name: 'Mohamed Karim',
        avatarUrl: null,
        rating: 4.8,
        reviewCount: 342,
        origin: 'Turquie',
        destination: 'Alger',
        availableKg: 30,
        totalKg: 50,
        pricePerKg: 1200,
        arrivalDate: DateTime.now().add(const Duration(days: 2)),
        onBook: () => booked = true,
      )));

      expect(find.text('Mohamed Karim'), findsOneWidget);
      expect(find.textContaining('4.8'), findsOneWidget);
      // 30/50 kg → 60% availability
      expect(find.textContaining('30.0/50.0 kg'), findsOneWidget);

      // Expanded stats hidden by default
      expect(find.text('Statistiques'), findsNothing);

      // Tap "Réserver"
      await tester.tap(find.text('Réserver'));
      expect(booked, isTrue);
    });

    testWidgets('expands stats on card tap', (tester) async {
      await tester.pumpWidget(_wrap(ShipperCard(
        shipperId: 's1',
        name: 'Fatima B.',
        rating: 4.6,
        origin: 'Chine',
        destination: 'Oran',
        availableKg: 8,
        totalKg: 20,
        pricePerKg: 900,
        arrivalDate: DateTime.now().add(const Duration(days: 1)),
        shipmentsCount: 1240,
        onBook: () {},
      )));

      expect(find.text('Statistiques'), findsNothing);
      await tester.tap(find.text('Fatima B.'));
      await tester.pumpAndSettle();
      expect(find.text('Statistiques'), findsOneWidget);
      expect(find.text('1.2k'), findsOneWidget);
    });
  });

  group('TrackingTimeline', () {
    testWidgets('renders events with status and description', (tester) async {
      await tester.pumpWidget(_wrap(TrackingTimeline(
        events: [
          TrackingEvent(
            title: 'Commande traitée',
            timestamp: DateTime.now(),
            status: TrackingStatus.completed,
            description: 'Bordereau créé',
          ),
          TrackingEvent(
            title: 'En transit',
            timestamp: DateTime.now(),
            status: TrackingStatus.inProgress,
          ),
        ],
      )));

      expect(find.text('Commande traitée'), findsOneWidget);
      expect(find.text('En transit'), findsOneWidget);
      expect(find.text('Bordereau créé'), findsOneWidget);
    });

    testWidgets('renders action buttons', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(TrackingTimeline(
        events: [
          TrackingEvent(
            title: 'Récupération',
            timestamp: DateTime.now(),
            status: TrackingStatus.pending,
            actions: [
              TrackingAction(
                label: 'Appeler',
                icon: Icons.call,
                onTap: () => tapped = true,
              ),
            ],
          ),
        ],
      )));

      await tester.tap(find.text('Appeler'));
      expect(tapped, isTrue);
    });
  });

  group('RevenueBarChart', () {
    testWidgets('renders a bar per data point', (tester) async {
      await tester.pumpWidget(_wrap(const RevenueBarChart(
        data: [
          RevenueBar(label: 'A', value: 10),
          RevenueBar(label: 'B', value: 30),
          RevenueBar(label: 'C', value: 20),
        ],
      )));

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('shows empty message when no data', (tester) async {
      await tester.pumpWidget(_wrap(const RevenueBarChart(data: [])));
      expect(find.textContaining('Pas encore de données'), findsOneWidget);
    });
  });
}
